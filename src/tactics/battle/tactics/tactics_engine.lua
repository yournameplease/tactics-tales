---@brief
--- The core engine for handling actions within a battle.
--- This service manages unit spawning, movement, combat, and interactions,
--- coordinating tasks, animations, and events.

local point = require("src.tactics.util.point")
local random = require("src.tactics.util.random")
local fp = require("src.tactics.util.fp")
local combat_calculator = require("src.tactics.battle.combat.combat_calculator")
local tile_reachability_cache = require("src.tactics.battle.tile_reachability_cache")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local lists = require("src.tactics.util.lists")
local id_generator = require("src.tactics.util.id_generator")
local mutex = require("src.tactics.systems.mutex")
local dialogue_manager = require("src.tactics.dialogue.dialogue_manager")

local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local unit_spawner = require("src.tactics.battle.unit_spawner")

local TILE_WIDTH = STATIC_CONFIG.TILE_WIDTH
local TILE_HEIGHT = STATIC_CONFIG.TILE_HEIGHT
local TILE_SIZE = point.of(TILE_WIDTH, TILE_HEIGHT)

---@class NewUnitProperties
---@field new_side Side
---@field new_ai UnitAI
---@field enabled? boolean

---@class QueuedBattleDialogue
---@field speaking_unit BattleUnit
---@field text string[]

---@class ActiveBattleDialogue
---@field speaking_unit BattleUnit
---@field dialogue ActiveDialogue

---@class TacticsEngine
---@field turn integer The current turn.  Set by TurnManager.
---@field chapter integer The current chapter.
---@field battle_config BattleConfig
---@field battle_is_blocked boolean Whether a coroutine is currently blocking battle input.
---@field script_mutex Mutex Counted mutex controlling script-lock state.
---@field active_point? Point
---@field battle_map BattleMap
---@field character_manager CharacterManager
---@field music_player MusicPlayer
---@field skill_defs table<string, SkillDefinition> Skill definitions for initialising unit skill states.
---@field id_generator IdGenerator
---@field task_manager TaskManager
---@field animation_manager AnimationManager
---@field event_writer EventWriter
---@field dialogue_manager DialogueManager
---@field dialogue_queue QueuedBattleDialogue[] Pending dialogues not yet displayed.
---@field active_dialogue? ActiveBattleDialogue Currently displayed dialogue, or nil if none.
---@field tile_reachability_cache TileReachabilityCache Cache of reachable tile maps and marked-unit overlay.
---@field dialogue_revision integer Incremented whenever the active dialogue changes.
---@field phase_banner {text: string, frames_remaining: integer}? Active phase banner, or nil if none.
local TacticsEngine = {}
TacticsEngine.__index = TacticsEngine

local tactics_engine = {
    TacticsEngine = TacticsEngine,
}

--- Construct a new TacticsEngine bound to the given battle services.
---@param chapter integer
---@param battle_config BattleConfig
---@param map BattleMap
---@param character_mgr CharacterManager
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param bus EventBus
---@param music_player MusicPlayer
---@param skill_defs? table<string, SkillDefinition>
---@return TacticsEngine
function tactics_engine.new(
    chapter,
    battle_config,
    map,
    character_mgr,
    task_manager,
    animation_manager,
    bus,
    music_player,
    skill_defs
)
    ---@type TacticsEngine
    local self = setmetatable({}, TacticsEngine)
    self.chapter = chapter
    self.turn = 1
    self.battle_is_blocked = false
    self.script_mutex = mutex.new()

    self.battle_config = battle_config
    self.battle_map = map
    self.character_manager = character_mgr
    self.music_player = music_player
    self.skill_defs = skill_defs or {}

    self.id_generator = id_generator.new()
    self.task_manager = task_manager
    self.animation_manager = animation_manager
    self.event_writer = event_writer.new(bus)
    self.dialogue_manager = dialogue_manager.new()
    self.dialogue_queue = {}
    self.tile_reachability_cache = tile_reachability_cache.new(map)

    self.dialogue_revision = 0
    self.phase_banner = nil

    return self
end

--- Acquire an exclusive lock and return its ID.
---@return integer
function TacticsEngine:acquire_lock()
    return self.script_mutex:acquire()
end

--- Release the lock with the given ID.
---@param lock_id integer
function TacticsEngine:remove_lock(lock_id)
    self.script_mutex:release(lock_id)
end

---@return boolean
function TacticsEngine:is_permadeath()
    return self.battle_config.permadeath
end

-- Normalize path to offsets from first tile and multiply by tile scale.
---@param path Point[]
---@return Point[]
local function to_tile_path(path)
    assert(#path > 0)

    local base_point = path[1]
    local normalize_point = function(p)
        return (p - base_point) * TILE_SIZE
    end
    return lists.map(normalize_point)(path)
end

--- Enqueue a dialogue line to be spoken by `unit`.
---@param unit BattleUnit
---@param text string[]
function TacticsEngine:start_dialogue(unit, text)
    table.insert(self.dialogue_queue, {
        speaking_unit = unit,
        text = text,
    })
end

--- Advance the dialogue queue, promote the next entry if idle, and dismiss finished dialogues.
---@param input InputContext
function TacticsEngine:update_dialogue(input)
    if #self.dialogue_queue > 0 then
        if self.active_dialogue == nil then
            local queued_dialogue = self.dialogue_queue[1]
            local new_dialogue = self.dialogue_manager:create_dialogue(
                queued_dialogue.text,
                {
                    can_skip = true,
                },
                {}
            )
            self.active_dialogue = {
                speaking_unit = queued_dialogue.speaking_unit,
                dialogue = new_dialogue,
            }
            table.remove(self.dialogue_queue, 1)
            self.dialogue_revision = self.dialogue_revision + 1
            log.debug("adding dialogue", #self.dialogue_queue, self.active_dialogue)
        end
    end
    self.dialogue_manager:update(input)
    if self.active_dialogue ~= nil and self.active_dialogue.dialogue.finished then
        log.debug("removing dialogue", #self.dialogue_queue, self.active_dialogue)
        self.active_dialogue = nil
        self.dialogue_revision = self.dialogue_revision + 1
    end
end

--- Place `unit` on the map at `spawn_point` with an idle animation.
---@param unit BattleUnit
---@param spawn_point Point
function TacticsEngine:spawn_unit(unit, spawn_point)
    local idle_animation = self.animation_manager:create_idle_animation()
    unit.animation_data = idle_animation
    self.battle_map:spawn_unit(unit, spawn_point)
    self:invalidate_tiles_for_point(spawn_point)
    log.debug("Spawned unit: " .. tostring(unit))
end

--- Remove each unit in `units` from the map.
---@param units BattleUnit[]
function TacticsEngine:despawn_unit(units)
    for _, unit in ipairs(units) do
        self.battle_map:remove_unit(unit.id)
    end
end

--- Iterate over unit definitions and spawn each via CharacterManager, respecting `blocked_behavior`.
--- Accepts both tile-label entries (UnitSpawnData) and squad/slot entries (LayerSpawnData).
---@param units (UnitSpawnData|LayerSpawnData)[]
---@param blocked_behavior UnitSpawnBlockedBehavior
---@return BattleUnit[]
function TacticsEngine:spawn_units(units, blocked_behavior)
    local spawned_units = {}
    local char_man = self.character_manager
    local player_roster = char_man:get_player_roster()
    -- this will duplicate players if multiple roster spawns are made
    local roster_count = 1

    for _, spawn_data in ipairs(units) do
        if spawn_data.layer then
            ---@cast spawn_data LayerSpawnData
            local group = self.battle_map.spawn_groups and self.battle_map.spawn_groups[spawn_data.layer]
            if group then
                local tags = spawn_data.tags or {}
                local labels = lists.merge(tags, { spawn_data.layer })
                for _, pt in ipairs(group.points) do
                    local slot_data = spawn_data.slots[pt.slot]
                    if slot_data then
                        local spawn_point = point.of(pt.x, pt.y)
                        local unit
                        unit, roster_count = unit_spawner.try_spawn_at(
                            self, char_man, player_roster, roster_count,
                            spawn_point, slot_data.character_source,
                            spawn_data.side, spawn_data.movement_side,
                            slot_data.ai, labels, blocked_behavior
                        )
                        if unit then table.insert(spawned_units, unit) end
                    end
                end
            end
        else
            ---@cast spawn_data UnitSpawnData
            local tile_label = spawn_data.tile
            local tags = spawn_data.tags or {}
            local labels = lists.merge(tags, { tile_label })
            local spawn_points = self.battle_map:get_tiles_by_label(spawn_data.tile)
            for _, spawn_point in ipairs(spawn_points) do
                local unit
                unit, roster_count = unit_spawner.try_spawn_at(
                    self, char_man, player_roster, roster_count,
                    spawn_point, spawn_data.character_source,
                    spawn_data.side, spawn_data.movement_side,
                    spawn_data.ai, labels, blocked_behavior, spawn_data.facing
                )
                if unit then table.insert(spawned_units, unit) end
            end
        end
    end
    return spawned_units
end

--- Spawn all units and optionally play a slide-in animation from the given direction.
---@param units (UnitSpawnData|LayerSpawnData)[]
---@param anim UnitSpawnAnimation?
---@param blocked_behavior UnitSpawnBlockedBehavior
function TacticsEngine:spawn_all(units, anim, blocked_behavior)
    local spawned = {}
    lists.add_all(spawned, self:spawn_units(units, blocked_behavior))

    log.debug("Spawned " .. #spawned .. " units.")
    if anim ~= nil and #spawned > 0 then
        log.debug("Animating spawned units")
        local max_offset = 0
        for _, unit in ipairs(spawned) do
            local offset
            if anim == "from_north" then
                offset = unit.tile.y + 1
            elseif anim == "from_south" then
                offset = self.battle_map.height - unit.tile.y
            elseif anim == "from_east" then
                offset = self.battle_map.width - unit.tile.x
            elseif anim == "from_west" then
                offset = unit.tile.x + 1
            else
                unexpected(anim)
            end
            if offset > max_offset then
                max_offset = offset
            end
        end

        local offset_point
        if anim == "from_north" then
            offset_point = point.of(0, -max_offset)
        elseif anim == "from_south" then
            offset_point = point.of(0, max_offset)
        elseif anim == "from_east" then
            offset_point = point.of(max_offset, 0)
        elseif anim == "from_west" then
            offset_point = point.of(-max_offset, 0)
        else
            unexpected(anim)
        end

        local path = { offset_point * TILE_SIZE, point.of(0, 0) }

        self.task_manager:start_routine(function()
            self.battle_is_blocked = true
            local spawn_animation = self.animation_manager:create_walk_animation(path, max_offset)

            for _, unit in ipairs(spawned) do
                unit.animation_data = spawn_animation
            end

            while spawn_animation.playing do
                yield()
            end

            local idle_animation = self.animation_manager:create_idle_animation()
            for _, unit in ipairs(spawned) do
                unit.animation_data = idle_animation
            end
            log.debug("Finished animating spawned units")
            self.battle_is_blocked = false
        end)
    end
end

--- Set `unit`'s animation to the idle animation.
---@param unit BattleUnit
function TacticsEngine:set_unit_idle(unit)
    unit.animation_data = self.animation_manager:create_idle_animation()
end

--- Mark `unit` as having acted and unblock battle input.
---@param unit BattleUnit
function TacticsEngine:finish_unit_action(unit)
    unit.has_acted = true

    self.battle_is_blocked = false
    unit.animation_data = self.animation_manager:create_idle_animation()
    unit.facing:turn_to("down")
    self.event_writer:emit("TACTICS_UNIT_END_ACTION", {})
end

--- Unmark all enemy units and clear the marked-unit tile overlay.
function TacticsEngine:handle_unmark_all_units()
    local all_enemies = self.battle_map:get_units(BattleUnit.is_enemy)

    for _, e in ipairs(all_enemies) do
        e.marked = false
    end
    self.tile_reachability_cache.marked_unit_tiles = self.tile_reachability_cache.marked_unit_tiles & 0
end

--- Mark all enemy units and recompute the tile overlay.
function TacticsEngine:handle_mark_all_units()
    local all_enemies = self.battle_map:get_units(BattleUnit.is_enemy)

    for _, e in ipairs(all_enemies) do
        e.marked = true
    end
    self.tile_reachability_cache:recompute_marked_unit_tiles()
end

--- Toggle the marked state of the enemy unit at tile `p`.
---@param p Point
function TacticsEngine:handle_mark_unit(p)
    local unit = self.battle_map:get_at_tile(p)
    if unit == nil then return end

    if unit:is_enemy() then
        local cache = self.tile_reachability_cache
        cache.marked_unit_revision = cache.marked_unit_revision + 1
        if unit.marked then
            unit.marked = false
            cache:recompute_marked_unit_tiles()
        else
            unit.marked = true
            cache:add_unit_to_marked_tiles(unit)
        end
    end
end

--- Emit a TACTICS_INTERACTION event and end `unit`'s action.
---@param interaction_id integer
---@param unit BattleUnit
---@param target_unit BattleUnit
---@param target_tile Point
function TacticsEngine:handle_interaction(interaction_id, unit, target_unit, target_tile)
    self.event_writer:emit("TACTICS_INTERACTION", {
        script_id = interaction_id,
        source_unit = unit,
        source_tile = unit.tile,
        target_unit = target_unit,
        target_tile = target_tile,
    })
    self:finish_unit_action(unit)
end

--- Animate and then commit `unit`'s move to `destination` along `path`.
---@param unit BattleUnit
---@param destination Point
---@param path Point[]
function TacticsEngine:move_unit(unit, destination, path)
    local previous_point = unit.tile:copy()

    self.battle_is_blocked = true
    if #path > 1 then
        local anim = self.animation_manager:create_walk_animation(to_tile_path(path))
        unit.animation_data = anim
        log.debug("Animating!", anim.playing)
        while anim.playing do
            yield()
        end
    end

    self.battle_map:move_unit(unit, destination)

    self:invalidate_tiles_for_point(previous_point)
    self:invalidate_tiles_for_point(unit.tile)

    self.battle_is_blocked = false
    self:set_unit_idle(unit)
end

--- Block battle input and run combat between `unit` and `target`.
---@param unit BattleUnit
---@param target BattleUnit
function TacticsEngine:attack_unit(unit, target)
    self.event_writer:emit("BEFORE_COMBAT", { attacker = unit, defender = target })
    self:yield_while_in_script()
    self.battle_is_blocked = true
    self:do_combat(unit, target)

    target.animation_data = self.animation_manager:create_idle_animation()
end

--- Play the death sequence for `defender` and remove it from the map.
--- Must be called from inside a coroutine.
---@param defender BattleUnit
---@param attacker? BattleUnit Unit that dealt the killing blow.
function TacticsEngine:kill_unit(defender, attacker)
    local defender_tile = defender.tile:copy()

    self.battle_is_blocked = true
    local anim = self.animation_manager:create_animation("DEATH", 0)
    defender.animation_data = anim
    local played_music = false

    if defender:is_player() then
        played_music = true
        self.music_player:push_music(9, 0)
        self:start_dialogue(defender, { "I've been slain..." })
    end

    self.battle_is_blocked = true
    while anim.playing or self.active_dialogue ~= nil do
        yield()
    end
    self.battle_is_blocked = false

    if self:is_permadeath() then
        defender:die()
    end
    self.battle_map:kill_unit(defender)
    if played_music then
        self.music_player:resume_music(1000)
    end

    self:invalidate_tiles_for_point(defender_tile)

    ---@type UnitDeathPayload
    local death_event = {
        attacker = attacker,
        defender = defender,
        chapter = self.chapter,
        turn_number = self.turn,
    }
    self.event_writer:emit("TACTICS_UNIT_DEATH", death_event)
end

--- Start a coroutine that moves `unit` to `destination` along `path`.
---@param unit BattleUnit
---@param destination Point
---@param path Point[]
function TacticsEngine:handle_move_unit(unit, destination, path)
    self.task_manager:start_routine(function()
        self:move_unit(unit, destination, path)
    end)
end

--- Start a coroutine that attacks `target` with `unit`, then ends the action.
---@param unit BattleUnit
---@param target BattleUnit
function TacticsEngine:handle_attack_unit(unit, target)
    self.task_manager:start_routine(function()
        self:attack_unit(unit, target)
        self:finish_unit_action(unit)
    end)
end

--- Execute a skill inside the current coroutine: deduct HP cost, apply effect,
--- process deaths, consume resources, then call finish_unit_action.
---@param caster BattleUnit
---@param skill_id string
---@param target BattleUnit
function TacticsEngine:skill_action(caster, skill_id, target)
    local skill = self.skill_defs[skill_id]

    local caster_dead = false
    local target_dead = false

    for _, effect in ipairs(skill.effects) do
        if effect.type == "hp_cost" then
            caster:take_damage(effect.amount)
            caster_dead = caster.hp_current <= 0
        elseif effect.type == "heal" then
            target:restore_hp(effect.amount)
        elseif effect.type == "damage" then
            -- TODO: check "damage_reduction" debuff on target and "defense_bonus" buff on target
            if random.rndi(100) < effect.accuracy then
                target:take_damage(effect.damage or 0)
                target_dead = target.hp_current <= 0
            end
        elseif effect.type == "debuff" or effect.type == "buff" then
            local status_target = effect.self_target and caster or target
            table.insert(status_target.active_statuses, { kind = effect.kind, duration = effect.duration, amount = effect.amount })
            if effect.kind == "move_bonus" or effect.kind == "move_lock" then
                self:invalidate_tiles_for_unit(status_target)
            end
        elseif effect.type == "refresh_action" then
            target.has_acted = false
        end
    end

    if caster_dead then
        self:kill_unit(caster)
    end
    if target_dead then
        self:kill_unit(target, caster)
    end

    local state = caster.skill_states[skill_id]
    state.cooldown_remaining = skill.cooldown or 0
    if state.uses_remaining ~= nil then
        state.uses_remaining = state.uses_remaining - 1
    end

    self:finish_unit_action(caster)
end

--- Start a coroutine that executes `skill_id` with `caster` targeting `target_tile`.
---@param caster BattleUnit
---@param skill_id string
---@param target_tile Point
function TacticsEngine:handle_skill(caster, skill_id, target_tile)
    self.task_manager:start_routine(function()
        local target = self.battle_map:get_at_tile(target_tile)
        ---@cast target BattleUnit
        self:skill_action(caster, skill_id, target)
    end)
end

--- Teleport `unit` to `destination` instantly with no animation.
---@param unit BattleUnit
---@param destination Point
function TacticsEngine:jump_unit_to_point(unit, destination)
    local previous_point = unit.tile:copy()

    self.battle_map:move_unit(unit, destination)

    self:invalidate_tiles_for_point(previous_point)
    self:invalidate_tiles_for_point(unit.tile)

    unit.facing.vertical = "down"
end

--- Start a coroutine that swaps the units on `swap_source` and `swap_target`.
---@param swap_source Point
---@param swap_target Point
function TacticsEngine:handle_swap_unit(swap_source, swap_target)
    self.task_manager:start_routine(function()
        self.battle_is_blocked = true

        -- todo: animate
        self.battle_map:swap_tile_units(swap_source, swap_target)

        self:invalidate_tiles_for_point(swap_source)
        self:invalidate_tiles_for_point(swap_target)

        self.battle_is_blocked = false
    end)
end

--- Start a coroutine that moves `unit` to `destination`, then ends the action.
---@param unit BattleUnit
---@param destination Point
---@param path Point[]
function TacticsEngine:handle_move_and_wait(unit, destination, path)
    self.task_manager:start_routine(function()
        self:move_unit(unit, destination, path)
        self:finish_unit_action(unit)
    end)
end

--- Start a coroutine that moves `unit` to `destination`, attacks `target`, then ends the action.
---@param unit BattleUnit
---@param destination Point
---@param path Point[]
---@param target BattleUnit
function TacticsEngine:handle_move_and_attack(unit, destination, path, target)
    self.task_manager:start_routine(function()
        self:move_unit(unit, destination, path)
        self:attack_unit(unit, target)
        self:finish_unit_action(unit)
    end)
end

--- Apply `new_unit_properties` to each unit in `units`.
---@param units BattleUnit[]
---@param new_unit_properties NewUnitProperties
function TacticsEngine:modify_units(units, new_unit_properties)
    for _, u in ipairs(units) do
        if new_unit_properties.new_ai ~= nil then
            u.unit_ai = new_unit_properties.new_ai
            self:invalidate_tiles_for_unit(u)
        end
        if new_unit_properties.new_side ~= nil then
            u.side = new_unit_properties.new_side
            self:invalidate_tiles_for_point(u.tile)
        end
        if new_unit_properties.enabled ~= nil then
            u.disabled = not new_unit_properties.enabled
        end
    end
end

--- Convert each unit in `units` to the player side and persist them to the roster.
---@param units BattleUnit[]
function TacticsEngine:recruit_units(units)
    for _, u in ipairs(units) do
        u.unit_ai = nil
        u.side = "player"
        self.character_manager:persist_player(u.character)

        self:invalidate_tiles_for_point(u.tile)
    end
end

-- Combat

--- Handle the visual and state consequences of a single combat step.
--- Plays attack and dodge animations, applies damage and equipment effects,
--- and checks if the defending unit has died.
---@param step CombatStep
function TacticsEngine:apply_combat_step(step)
    local attacker = step.attacker
    local defender = step.defender

    local direction = atan2(
        defender.tile.x - attacker.tile.x,
        defender.tile.y - attacker.tile.y
    )

    local attack_animation = self.animation_manager:create_animation("BUMP", direction)
    attacker.animation_data = attack_animation
    if step.is_hit then
        sfx(8)
    else
        sfx(9)
        local dodge_animation = self.animation_manager:create_animation("DODGE", direction + 0.25)
        defender.animation_data = dodge_animation
        while dodge_animation.playing do
            yield()
        end
    end
    while attack_animation.playing do
        yield()
    end

    if step.is_hit then
        if step.destroy_shield then
            local off_hand = defender.character.inventory:get_equipped_items()["OFF_HAND"]
            -- lazy, probably should temp disable or destroy instead
            if off_hand ~= nil and off_hand.name == "shield" then
                defender.character.inventory:unequip_item_in_equip_slot("OFF_HAND")
                defender.sprites = {}
            end
        end

        defender:take_damage(step.dmg)
        local hurt_animation = self.animation_manager:create_animation("HURT", direction)
        defender.animation_data = hurt_animation

        while hurt_animation.playing do
            yield()
        end
    end

    if defender.hp_current <= 0 then
        self:kill_unit(defender, attacker)
    end
end

--- Run all combat steps between `attacker` and `defender`, animating each.
---@param attacker BattleUnit
---@param defender BattleUnit
function TacticsEngine:do_combat(attacker, defender)
    local delta = attacker.tile - defender.tile
    defender.facing:face_point(delta, true)
    attacker.facing:face_point(-delta, true)

    -- TODO: check "double_attack" buff on attacker for extra attack step
    local combat_result = combat_calculator.compute_combat(attacker, defender, self.battle_map)

    self.event_writer:emit("UNIT_COMBAT", {
        attacker_id = attacker.id,
        defender_id = defender.id,
        chapter = self.chapter,
    })

    for i, combat_step in ipairs(combat_result.steps) do
        log.debug("Combat step: ", i)
        self:apply_combat_step(combat_step)
        if combat_step.attacker.id == attacker.id then
            self.battle_is_blocked = false
            self.event_writer:emit("BEFORE_COUNTERATTACK", { attacker = attacker, defender = defender })
            self:yield_while_in_script()
            self.battle_is_blocked = true
        end
    end

    if defender then
        defender.facing:turn_to("down")
    end
    if attacker then
        attacker.facing:turn_to("down")
    end
end

-- Turn flow

--- Tick skill cooldowns for all units on the given side.
---@param side Side
function TacticsEngine:tick_skill_cooldowns_for_side(side)
    local units = self.battle_map:get_units(function(u) return u.side == side end)
    for _, unit in ipairs(units) do
        unit:tick_skill_cooldowns()
        unit:tick_statuses()
    end
end

--- Reset `has_acted` on every unit on the map.
function TacticsEngine:refresh_all_units()
    self:refresh_units(fp.fn_true)
end

--- Reset `has_acted` on all units passing `filter`.
---@param filter fun(unit: BattleUnit): boolean
function TacticsEngine:refresh_units(filter)
    local units_to_refresh = self.battle_map:get_units(filter)

    for _, unit in ipairs(units_to_refresh) do
        unit.has_acted = false
    end
end

--- Return true if dialogue or a running animation is blocking input.
---@return boolean
function TacticsEngine:is_blocked()
    local is_dialogue = #self.dialogue_queue > 0 or self.active_dialogue ~= nil

    return is_dialogue or self.battle_is_blocked
end

--- Return true if any script lock is currently held.
---@return boolean
function TacticsEngine:is_locked()
    return self.script_mutex:is_locked()
end

--- Return true if blocked by animation/dialogue or by a held script lock.
---@return boolean
function TacticsEngine:is_hard_blocked()
    return self:is_blocked() or self:is_locked()
end

--- Yield until all held script locks are released.
function TacticsEngine:yield_while_in_script()
    while self:is_locked() do
        yield()
    end
end

-- Legal tile getters — implementations live in TileReachabilityCache

---@param unit BattleUnit
---@param tile Point
---@return userdata_2d
function TacticsEngine:tiles_with_distance_from_unit_attacks(unit, tile)
    return self.tile_reachability_cache:_tiles_with_distance_from_unit_attacks(unit, tile)
end

---@param unit BattleUnit
---@return userdata_2d
function TacticsEngine:get_valid_tiles_for_unit(unit)
    return self.tile_reachability_cache:get_valid_tiles_for_unit(unit)
end

---@param unit BattleUnit
function TacticsEngine:invalidate_tiles_for_unit(unit)
    self.tile_reachability_cache:invalidate_tiles_for_unit(unit)
end

---@param p Point
function TacticsEngine:invalidate_tiles_for_point(p)
    self.tile_reachability_cache:invalidate_tiles_for_point(p)
end

--- Show a phase banner with the given text for PHASE_BANNER_DURATION frames.
---@param text string
function TacticsEngine:show_phase_banner(text)
    self.phase_banner = { text = text, frames_remaining = STATIC_CONFIG.PHASE_BANNER_DURATION }
    self.battle_is_blocked = true
end

--- Advance dialogue state each frame.
---@param input InputContext
function TacticsEngine:update(input)
    self:update_dialogue(input)
    if self.phase_banner ~= nil then
        self.phase_banner.frames_remaining = self.phase_banner.frames_remaining - 1
        if self.phase_banner.frames_remaining <= 0 then
            self.phase_banner = nil
            self.battle_is_blocked = false
        end
    end
end

return tactics_engine
