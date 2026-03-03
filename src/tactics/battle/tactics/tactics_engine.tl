---@brief
--- The core engine for handling actions within a battle.
--- This service manages unit spawning, movement, combat, and interactions,
--- coordinating tasks, animations, and events.

require("src.tactics.config")

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local point = require("src.tactics.util.point")
local Point = point.Point
local fp = require("src.tactics.util.fp")
local array_2d = require("src.tactics.util.array_2d")
local pathfinding = require("src.tactics.battle.pathfinding")
local combat_calculator = require("src.tactics.battle.combat.combat_calculator")
local event_bus = require("src.tactics.systems.event_bus")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local bm = require("src.tactics.battle.battle_map")
local tasks = require("src.tactics.systems.tasks")
local animation = require("src.tactics.animation")
local lists = require("src.tactics.util.lists")
local id_generator = require("src.tactics.util.id_generator")
local maps = require("src.tactics.util.maps")
local Set = maps.Set
local unit_spawn_data = require("src.tactics.battle.unit.spawn_data")
local unit_ai = require("src.tactics.battle.unit.unit_ai")
local character = require("src.tactics.character.object.character")
local Character = character.Character
local dialogue_manager = require("src.tactics.dialogue.dialogue_manager")
local DialogueManager = dialogue_manager.DialogueManager
local Dialogue = require("src.tactics.dialogue.dialogue").Dialogue

local InputContext = require("src.tactics.input.input_context").InputContext
local character_manager = require("src.tactics.character.character_manager")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit

local MAP_WIDTH = STATIC_CONFIG.MAP_WIDTH
local MAP_HEIGHT = STATIC_CONFIG.MAP_HEIGHT

local TILE_WIDTH = STATIC_CONFIG.TILE_WIDTH
local TILE_HEIGHT = STATIC_CONFIG.TILE_HEIGHT
local TILE_SIZE = point.of(TILE_WIDTH, TILE_HEIGHT)

local record NewUnitProperties
    new_side: battle_unit.Side
    new_ai: unit_ai.UnitAI
end

local record QueuedBattleDialogue
    speaking_unit: BattleUnit
    text: {string}
end

local record ActiveBattleDialogue
    speaking_unit: BattleUnit
    dialogue: Dialogue
end

local record TacticsEngine
    
    battle_is_blocked: boolean
    tactics_locks: Set<integer>

    active_point: Point

    battle_map: bm.BattleMap
    character_manager: character_manager.CharacterManager

    id_generator: id_generator.IdGenerator
    task_manager: tasks.TaskManager
    animation_manager: animation.AnimationManager
    event_writer: event_writer.EventWriter
    dialogue_manager: DialogueManager
    dialogue_queue: {QueuedBattleDialogue}
    active_dialogue: ActiveBattleDialogue

    valid_tiles_by_unit: {integer: Userdata}

    -- queries
    
    is_blocked: function(self): boolean
    tiles_with_distance_from_unit_attacks: function(self, unit: BattleUnit, point: Point): Userdata
    find_tiles_with_distance_from_tile: function(self, integer, integer, integer, integer): array_2d.Array2D<boolean>
    
    get_valid_tiles_for_unit: function(self, unit: BattleUnit): Userdata
    invalidate_tiles_for_unit: function(self, unit: BattleUnit)
    invalidate_tiles_for_point: function(self, p: Point)
    
    -- mutations
    spawn_all: function(
        self,
        players: {unit_spawn_data.UnitSpawnData},
        enemies: {unit_spawn_data.UnitSpawnData},
        neutrals: {unit_spawn_data.UnitSpawnData},
        animation: unit_spawn_data.UnitSpawnAnimation,
        blocked_behavior: unit_spawn_data.UnitSpawnBlockedBehavior
    )
    handle_mark_unit: function(self, Point)
    handle_interaction: function(self,
        interaction_id: integer,
        unit: BattleUnit,
        target_unit: BattleUnit,
        target_tile: Point
    )
    set_unit_idle: function(self, BattleUnit)
    finish_unit_action: function(self, BattleUnit)
    handle_swap_unit: function(self,
        swap_source: Point,
        swap_target: Point
    )
    handle_move_unit: function(self,
        unit: BattleUnit,
        destination: Point,
        path: {Point}
    )
    handle_move_and_wait: function(self,
        unit: BattleUnit,
        destination: Point,
        path: {Point}
    )
    jump_unit_to_point: function(self,
        unit: BattleUnit,
        destination: Point
    )
    handle_attack_unit: function(self,
        unit: BattleUnit,
        target: BattleUnit
    )
    handle_move_and_attack: function(self,
        unit: BattleUnit,
        destination: Point,
        path: {Point},
        target: BattleUnit
    )
    do_combat: function(self, BattleUnit, BattleUnit)
    refresh_all_units: function(self)
    refresh_units: function(self, function(BattleUnit): boolean)
    modify_units: function(self, units: {BattleUnit}, new_unit_properties: NewUnitProperties)
    recruit_units: function(self, units: {BattleUnit})
    tiles_in_movement_and_attack_range_for_unit: function(self, unit): Userdata
    
    update: function(self, InputContext)

    marked_unit_tiles: Userdata
    marked_unit_revision: integer
    dialogue_revision: integer
end

local tactics_engine = {
    ActiveBattleDialogue = ActiveBattleDialogue,
    TacticsEngine = TacticsEngine
}

function tactics_engine.new(
    map: bm.BattleMap,
    character_mgr: character_manager.CharacterManager,
    task_manager: tasks.TaskManager,
    animation_manager: animation.AnimationManager,
    bus: event_bus.EventBus
): tactics_engine.TacticsEngine
    local self: tactics_engine.TacticsEngine = setmetatable({
    }, { __index = TacticsEngine })
    self.battle_is_blocked = false
    self.tactics_locks = {}

    self.battle_map = map
    self.character_manager = character_mgr

    self.id_generator = id_generator.new()
    self.task_manager = task_manager
    self.animation_manager = animation_manager
    self.event_writer = event_writer.new(bus)
    self.dialogue_manager = dialogue_manager.new()
    self.dialogue_queue = {}
    self.valid_tiles_by_unit = {}

    self.marked_unit_revision = 0
    self.marked_unit_tiles = pt.userdata("u8", self.battle_map.width, self.battle_map.height)
    self.dialogue_revision = 0
    
    return self
end

function TacticsEngine:acquire_lock(): integer
    local id = self.id_generator:get_id()
    self.tactics_locks[id] = true
    return id
end

function TacticsEngine:remove_lock(lock_id: integer)
    self.tactics_locks[lock_id] = nil
end

-- normalize to offsets from first tile
-- multiply by tile scale
local function to_tile_path(path: { Point }): { Point }
    assert(#path > 0)
    --if #path == 0 then return path end

    local base_point = path[1]
    local normalize_point: function(Point): Point =
        function(p: Point): Point
            return (p - base_point) * TILE_SIZE
        end
    return lists.map(normalize_point)(path)
end

-- dialogue

function TacticsEngine:start_dialogue(unit: battle_unit.BattleUnit, text: {string})
    pt.add(self.dialogue_queue, {
        speaking_unit = unit,
        text = text,
    })
end

function TacticsEngine:update_dialogue(input: InputContext)
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
            pt.deli(self.dialogue_queue, 1)
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


-- unit spawning

function TacticsEngine:spawn_unit(unit: battle_unit.BattleUnit, spawn_point: Point)
    local idle_animation = self.animation_manager:create_idle_animation()
    unit.animation_data = idle_animation
    self.battle_map:spawn_unit(unit, spawn_point)
    log.debug("Spawned unit: "..tostring(unit))
end

function TacticsEngine:despawn_unit(units: {battle_unit.BattleUnit})
    for _,unit in ipairs(units) do
        self.battle_map:remove_unit(unit.id)
    end
end

--- Iterates over unit definitions and calls CharacterManager
function TacticsEngine:spawn_units(
    units: {unit_spawn_data.UnitSpawnData},
    side: battle_unit.Side,
    blocked_behavior: unit_spawn_data.UnitSpawnBlockedBehavior
): {battle_unit.BattleUnit}
    local spawned_units: {battle_unit.BattleUnit} = {}
    local char_man = self.character_manager
    local player_roster = char_man:get_player_roster()
    -- this will duplicate players if multiple roster spawns are made
    local roster_count = 1

    for _, spawn_data in ipairs(units) do
        local tile_label = spawn_data.tile
        local tags = spawn_data.tags or {}
        local labels = lists.merge(tags, {tile_label})

        local spawn_points = self.battle_map:get_tiles_by_label(spawn_data.tile)
        for _,spawn_point in ipairs(spawn_points) do
            local existing_unit = self.battle_map:get_at_tile(spawn_point)
            local should_spawn = true

            if existing_unit ~= nil then
                if blocked_behavior == "prevent" then
                    should_spawn = false
                elseif blocked_behavior == "spawn_nearby" then
                    -- todo
                else
                    unexpected(blocked_behavior)
                end
            end

            if should_spawn then
                local unit_character: Character = nil

                local character_source = spawn_data.character_source
                if character_source is unit_spawn_data.character_source.CharacterTemplateSource then
                    unit_character = char_man:generate_character(character_source.template, {})
                    if side == "player" then
                        char_man:persist_player(unit_character)
                    end
                elseif character_source is unit_spawn_data.character_source.PlayerRosterSource then
                    if player_roster[roster_count] ~= nil then
                        unit_character = player_roster[roster_count]
                        roster_count = roster_count + 1
                    end
                else
                    unexpected(character_source.type)
                end
                if unit_character ~= nil then
                    local facing_r = spawn_point.x <= (MAP_WIDTH >> 1)
                    local unit = battle_unit.spawn_unit(
                        unit_character,
                        spawn_point,
                        labels,
                        side,
                        character.facing.of(facing_r and "right" or "left"),
                        spawn_data.ai
                    )
            
                    self:spawn_unit(unit, spawn_point)
                    pt.add(spawned_units, unit)
                end
            end
        end
    end
    return spawned_units
end

function TacticsEngine:spawn_all(
    players: {unit_spawn_data.UnitSpawnData},
    enemies: {unit_spawn_data.UnitSpawnData},
    neutral: {unit_spawn_data.UnitSpawnData},
    anim: unit_spawn_data.UnitSpawnAnimation,
    blocked_behavior: unit_spawn_data.UnitSpawnBlockedBehavior
)
    local spawned: {battle_unit.BattleUnit} = {}
    lists.add_all(spawned, self:spawn_units(players or {}, "player", blocked_behavior))
    lists.add_all(spawned, self:spawn_units(enemies or {}, "enemy", blocked_behavior))
    lists.add_all(spawned, self:spawn_units(neutral or {}, "neutral", blocked_behavior))

    log.debug("Spawned "..#spawned.." units.")
    if anim ~= nil and #spawned > 0 then
        log.debug("Animating spawned units")
        local max_offset = 0
        for _,unit in ipairs(spawned) do
            local offset: integer
            if anim == "from_north" then
                offset = unit.tile.y + 1
            elseif anim == "from_south" then
                offset = MAP_HEIGHT - unit.tile.y
            elseif anim == "from_east" then
                offset = MAP_WIDTH - unit.tile.x
            elseif anim == "from_west" then
                offset = unit.tile.x + 1
            else
                unexpected(anim)
            end
            if offset > max_offset then
                max_offset = offset 
            end
        end

        local offset_point: Point
        if anim == "from_north" then
            offset_point = point.of(0,-max_offset)
        elseif anim == "from_south" then
            offset_point = point.of(0,max_offset)
        elseif anim == "from_east" then
            offset_point = point.of(max_offset,0)
        elseif anim == "from_west" then
            offset_point = point.of(-max_offset,0)
        else
            unexpected(anim)
        end

        local path = { offset_point * TILE_SIZE, point.of(0,0) }

        self.task_manager:start_routine(function()
            self.battle_is_blocked = true
            local spawn_animation = self.animation_manager:create_walk_animation(path, max_offset)

            for _,unit in ipairs(spawned) do
                unit.animation_data = spawn_animation
            end

            while spawn_animation.playing do
                pt.yield()
            end

            local idle_animation = self.animation_manager:create_idle_animation()
            for _,unit in ipairs(spawned) do
                unit.animation_data = idle_animation
            end
            log.debug("Finished animating spawned units")
            self.battle_is_blocked = false
        end)
    end
end

-- handlers


function TacticsEngine:set_unit_idle(unit: BattleUnit)
    unit.animation_data = self.animation_manager:create_idle_animation()
end

function TacticsEngine:finish_unit_action(unit: BattleUnit)
    unit.has_acted = true

    self.battle_is_blocked = false
    unit.animation_data = self.animation_manager:create_idle_animation()
    unit.facing:turn_to("down")
    self.event_writer:emit("TACTICS_UNIT_END_ACTION", {})
end

function TacticsEngine:recompute_marked_unit_tiles()
    local marked_units = self.battle_map:get_units(BattleUnit.is_marked)

    self.marked_unit_tiles = self.marked_unit_tiles - self.marked_unit_tiles
    for _,unit in ipairs(marked_units) do
        self.marked_unit_tiles = self.marked_unit_tiles
            | ((self.valid_tiles_by_unit[unit.id] & HIGHLIGHT.CAN_ATTACK) << 1)
    end
end

function TacticsEngine:handle_unmark_all_units()
    local all_enemies = self.battle_map:get_units(BattleUnit.is_enemy)

    for _,e in ipairs(all_enemies) do
        e.marked = false
    end
    self.marked_unit_tiles = self.marked_unit_tiles & 0
end

function TacticsEngine:handle_mark_all_units()
    local all_enemies = self.battle_map:get_units(BattleUnit.is_enemy)

    for _,e in ipairs(all_enemies) do
        e.marked = true
    end
    self:recompute_marked_unit_tiles()
end

function TacticsEngine:handle_mark_unit(p: Point)
    local unit = self.battle_map:get_at_tile(p)
    if unit == nil then return end

    if unit:is_enemy() then
        self.marked_unit_revision = self.marked_unit_revision + 1
        if unit.marked then
            unit.marked = false
            self:recompute_marked_unit_tiles()
        else
            unit.marked = true
            self.marked_unit_tiles = self.marked_unit_tiles
                | ((self.valid_tiles_by_unit[unit.id] & HIGHLIGHT.CAN_ATTACK) << 1)
        end
    end
end

function TacticsEngine:handle_interaction(
    interaction_id: integer,
    unit: BattleUnit,
    target_unit: BattleUnit,
    target_tile: Point
)
    self.event_writer:emit("TACTICS_INTERACTION", {
        script_id = interaction_id,
        source_unit = unit,
        source_tile = unit.tile,
        target_unit = target_unit,
        target_tile = target_tile,
    })
    self:finish_unit_action(unit)
end

function TacticsEngine:move_unit(
    unit: BattleUnit,
    destination: Point,
    path: {Point}
)
    local previous_point = unit.tile:copy()
    
    self.battle_is_blocked = true
    if #path > 1 then
        local anim = self.animation_manager:create_walk_animation(to_tile_path(path))
        unit.animation_data = anim
        log.debug("Animating!", anim.playing)
        while anim.playing do
            pt.yield()
        end
    end

    self.battle_map:move_unit(unit, destination)

    self:invalidate_tiles_for_point(previous_point)
    self:invalidate_tiles_for_point(unit.tile)

    self.battle_is_blocked = false
    self:set_unit_idle(unit)
end

function TacticsEngine:attack_unit(
    unit: BattleUnit, 
    target: BattleUnit 
)
    self.battle_is_blocked = true
    self:do_combat(unit, target)

    target.animation_data = self.animation_manager:create_idle_animation()
end

-- to be called inside a coroutine
function TacticsEngine:kill_unit(
    defender: BattleUnit,
    attacker: BattleUnit -- nillable
)
    local defender_tile = defender.tile:copy()
    
    self.battle_is_blocked = true
    local anim = self.animation_manager:create_animation("DEATH", 0)    
    defender.animation_data = anim

    if defender:is_player() then
        pt.music(9)
        self:start_dialogue(defender, {"I've been slain..."})
    end
    
    self.battle_is_blocked = true
    while anim.playing or self.active_dialogue ~= nil do
        pt.yield()
    end
    self.battle_is_blocked = false
    
    defender:die()
    self.battle_map:kill_unit(defender)

    self:invalidate_tiles_for_point(defender_tile)

    self.event_writer:emit("TACTICS_UNIT_DEATH", {
        attacker = attacker,
        defender = defender,
    })   
end

function TacticsEngine:handle_move_unit(
    unit: BattleUnit,
    destination: Point,
    path: {Point}
)
    self.task_manager:start_routine(function()
        self:move_unit(
            unit,
            destination,
            path
        )
    end)
end

function TacticsEngine:handle_attack_unit(
    unit: BattleUnit,
    target: BattleUnit 
)
    self.task_manager:start_routine(function()
        self:attack_unit(
            unit,
            target
        )
        self:finish_unit_action(
            unit
        )
    end)
end

function TacticsEngine:jump_unit_to_point(
    unit: BattleUnit,
    destination: Point
)
    local previous_point = unit.tile:copy()

    self.battle_map:move_unit(unit, destination)

    self:invalidate_tiles_for_point(previous_point)
    self:invalidate_tiles_for_point(unit.tile)

    unit.facing.vertical = "down"
end

function TacticsEngine:handle_swap_unit(
    swap_source: Point,
    swap_target: Point
)
    self.task_manager:start_routine(function()
        self.battle_is_blocked = true

        -- todo: animate
        self.battle_map:swap_tile_units(swap_source, swap_target)

        self:invalidate_tiles_for_point(swap_source)
        self:invalidate_tiles_for_point(swap_target)
        
        self.battle_is_blocked = false
    end)
end

function TacticsEngine:handle_move_and_wait(
    unit: BattleUnit,
    destination: Point,
    path: {Point}
)
    self.task_manager:start_routine(function()
        self:move_unit(unit, destination, path)
        self:finish_unit_action(unit)
    end)
end

function TacticsEngine:handle_move_and_attack(
    unit: BattleUnit,
    destination: Point,
    path: {Point},
    target: BattleUnit
)
    self.task_manager:start_routine(function()
        self:move_unit(unit, destination, path)
        self:attack_unit(unit, target)
        self:finish_unit_action(unit)
    end)
end

function TacticsEngine:modify_units(units: {BattleUnit}, new_unit_properties: NewUnitProperties)
    for _,u in ipairs(units) do
        if new_unit_properties.new_ai ~= nil then
            u.unit_ai = new_unit_properties.new_ai
            self:invalidate_tiles_for_unit(u)
        end
        if new_unit_properties.new_side ~= nil then
            u.side = new_unit_properties.new_side
            self:invalidate_tiles_for_point(u.tile)
        end
    end
end

function TacticsEngine:recruit_units(units: {BattleUnit})
    for _,u in ipairs(units) do
        u.unit_ai = nil
        u.side = "player"
        self.character_manager:persist_player(u.character)

        self:invalidate_tiles_for_point(u.tile)
    end
end

-- Combat

---@desc
--- Handles the visual and state-related consequences of a single combat step.
--- This includes playing attack and dodge animations, applying damage and
--- equipment effects, and checking if the defending unit has died.
function TacticsEngine:apply_combat_step(step: combat_calculator.CombatResult.CombatStep)
    local attacker = step.attacker
    local defender = step.defender

    local direction = pt.atan2(
            defender.tile.x - attacker.tile.x,
            defender.tile.y - attacker.tile.y
    )

    local attack_animation = self.animation_manager:create_animation("BUMP", direction)
    attacker.animation_data = attack_animation
    if step.is_hit then
        pt.sfx(8)
    else
        pt.sfx(9)
        local dodge_animation = self.animation_manager:create_animation("DODGE", direction + 0.25)
        defender.animation_data = dodge_animation
        while dodge_animation.playing do
            pt.yield()
        end
    end
    while attack_animation.playing do
        pt.yield()
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
            pt.yield()
        end
    end

    if not defender:is_alive() then
        self:kill_unit(defender, attacker)
    end
end

function TacticsEngine:do_combat(attacker: BattleUnit, defender: BattleUnit)
    local delta = attacker.tile - defender.tile
    defender.facing:face_point(delta, true)
    attacker.facing:face_point(-delta, true)
    
    local combat_result: combat_calculator.CombatResult = combat_calculator.compute_combat(attacker, defender, self.battle_map)

    for i,combat_step in ipairs(combat_result.steps) do
        log.debug("Combat step: ",i)
        self:apply_combat_step(combat_step as combat_calculator.CombatResult.CombatStep)
    end

    if defender then
        defender.facing:turn_to("down")
    end
    if attacker then
        attacker.facing:turn_to("down")
    end
end

-- Turn flow

function TacticsEngine:refresh_all_units()
    self:refresh_units(fp.fn_true)
end

function TacticsEngine:refresh_units(filter: function(BattleUnit): boolean)
    local units_to_refresh = self.battle_map:get_units(filter)

    for _,unit in ipairs(units_to_refresh) do
        unit.has_acted = false
    end
end

function TacticsEngine:is_blocked(): boolean
    local is_dialogue = #self.dialogue_queue > 0 or self.active_dialogue ~= nil

    return is_dialogue or self.battle_is_blocked
end

function TacticsEngine:is_locked(): boolean
    for _,_ in pairs(self.tactics_locks) do
        return true
    end
    return false
end

function TacticsEngine:is_hard_blocked(): boolean
    return self:is_blocked() or self:is_locked()
end

function TacticsEngine:yield_while_in_script()
    while self:is_locked() do
        pt.yield()
    end
end

-- legal tile getters

function TacticsEngine:tiles_with_distance_from_unit_attacks(unit: BattleUnit, tile: Point): Userdata
    local targeting = unit.character:get_weapon_targeting()

    local tiles_in_distance = targeting.get_selection_tiles(tile, self.battle_map)

    local tiles = pt.userdata("u8", MAP_WIDTH, MAP_HEIGHT)

    for _,t in ipairs(tiles_in_distance) do
        tiles:set(t.x, t.y, HIGHLIGHT.CAN_ATTACK | HIGHLIGHT.IS_VALID)
    end

    return tiles
end

function TacticsEngine:find_tiles_with_distance_from_tile(tile_x: integer, tile_y: integer, min_distance: integer, max_distance: integer): array_2d.Array2D<boolean>
    max_distance = max_distance or min_distance

    local reachable = array_2d.new(MAP_WIDTH, MAP_HEIGHT, false)
    for x=-max_distance,max_distance do
        local map_x = x + tile_x
        if map_x >= 0 and map_x < MAP_WIDTH then
            local abs_x = pt.abs(x)
            local min_y_abs = pt.max(0, min_distance-abs_x)
            local max_y_abs = max_distance-abs_x

            if max_y_abs >= min_y_abs then
                for y=-max_y_abs,-min_y_abs do
                    local map_y = y + tile_y
                    if map_y >= 0 and map_y < MAP_HEIGHT then
                        reachable:set(map_x, map_y, true)
                    end
                end
                for y=min_y_abs,max_y_abs do
                    local map_y = y + tile_y
                    if map_y >= 0 and map_y < MAP_HEIGHT then
                        reachable:set(map_x, map_y, true)
                    end
                end
            end
        end
    end

    return reachable

end

---@desc
--- Returns a u8 Userdata whose bits signify:
--- 0x1 - reachable
--- 0x2 - is valid selection
--- 0x4 - can attack
function TacticsEngine:tiles_in_movement_and_attack_range_for_unit(
    unit: BattleUnit
): Userdata
    local movement = unit.character.stats.movement
    if unit.unit_ai ~= nil and unit.unit_ai.move == "zero" then
        movement = 0
    end

    local reachable_tiles = pathfinding.find_reachable_tiles(
        self.battle_map,
        unit.tile.x,
        unit.tile.y,
        unit.side,
        movement
    )

    local tiles: Userdata = pt.userdata("u8", MAP_WIDTH, MAP_HEIGHT)
    
    reachable_tiles:foreach(function(x: integer, y: integer, reachable: boolean)
        if reachable then
            local tile = tiles:get(x, y)
            tile = tile | HIGHLIGHT.IS_VALID
            tile = tile | HIGHLIGHT.IS_REACHABLE
            tiles:set(x, y, tile)
            
            local tiles_in_attack_range = self:tiles_with_distance_from_unit_attacks(unit, point.of(x, y))
            tiles = tiles | ((tiles_in_attack_range & HIGHLIGHT.IS_VALID) << 1)
        end
    end)

    return tiles
end

function TacticsEngine:get_valid_tiles_for_unit(unit: BattleUnit): Userdata
    if self.valid_tiles_by_unit[unit.id] == nil then
        self.valid_tiles_by_unit[unit.id] = self:tiles_in_movement_and_attack_range_for_unit(unit)
    end
    return self.valid_tiles_by_unit[unit.id]
end

function TacticsEngine:invalidate_tiles_for_unit(unit: BattleUnit)
    self.valid_tiles_by_unit[unit.id] = nil
end

function TacticsEngine:invalidate_tiles_for_point(p: Point)
    for id,_ in pairs(self.valid_tiles_by_unit) do
        local unit = self.battle_map:get_unit_by_id(id)
        if point.taxicab_distance(unit.tile, p) <= unit.character.stats.movement then
            self.valid_tiles_by_unit[id] = nil
        end
    end
end

function TacticsEngine:update(input: InputContext)
    self:update_dialogue(input)
end

return tactics_engine
