require("src/tactics/config")
require("src/tactics/debug")

require ("src/tactics/menu/types")

require("src/tactics/util")
local array_2d = require("src/tactics/util/array_2d")
local pathfinding = require("src/tactics/battle/pathfinding")
local combat_calculator = require("src/tactics/battle/combat/combat_calculator")
local event_bus = require("src/tactics/systems/event_bus")
local event_writer = require("src/tactics/systems/event_bus/event_writer")
require("src/tactics/systems/tasks")
require("src/tactics/animation")
local lists = require("src/tactics/util/lists")
local unit_spawn_data = require("src/tactics/battle/unit/spawn_data")

local character_manager = require("src/tactics/character/character_manager")
local battle_unit = require("src/tactics/battle/tactics/battle_unit")

local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_HEIGHT

local TILE_SIZE = CONFIG.TILE_SIZE

local record TacticsEngine

    battle_is_blocked: boolean
    is_player_turn: boolean

    battle_map: BattleMap
    character_manager: character_manager.CharacterManager

    task_manager: TaskManager
    animation_manager: AnimationManager
    event_writer: event_writer.EventWriter


    spawn_all: function(self, players: {unit_spawn_data.UnitSpawnData}, enemies: {unit_spawn_data.UnitSpawnData}, neutrals: {unit_spawn_data.UnitSpawnData}, animation: unit_spawn_data.UnitSpawnAnimation)
    handle_move_unit: function(self, MenuContext)
    handle_move_and_attack: function(self, MenuContext)
    do_combat: function(self, BattleUnit, BattleUnit)
    refresh_all_units: function(self)
    refresh_units: function(self, function(BattleUnit): boolean)
    is_blocked: function(self): boolean
    tiles_with_distance_from_unit_attacks: function(self, MenuContext): array_2d.Array2D<MenuTileHighlight>
    find_tiles_with_distance_from_tile: function(self, integer, integer, integer, integer): array_2d.Array2D<boolean>
    tiles_in_movement_and_attack_range: function(self, MenuContext): array_2d.Array2D<MenuTileHighlight>
    update: function(self)
end

local tactics_engine = {
    TacticsEngine = TacticsEngine
}

function tactics_engine.new(
    battle_map: BattleMap,
    character_mgr: character_manager.CharacterManager,
    task_manager: TaskManager,
    animation_manager: AnimationManager,
    bus: event_bus.EventBus
): tactics_engine.TacticsEngine
    local self: tactics_engine.TacticsEngine = setmetatable({
    }, { __index = TacticsEngine })
    self.battle_is_blocked = false

    self.battle_map = battle_map
    self.character_manager = character_mgr

    self.task_manager = task_manager
    self.animation_manager = animation_manager
    self.event_writer = event_writer.new(bus)
    
    return self
end

-- unit spawning

function TacticsEngine:spawn_unit(unit: battle_unit.BattleUnit, spawn_point: Point)
    local idle_animation = self.animation_manager:create_idle_animation()
    unit.animation_data = idle_animation
    self.battle_map:spawn_unit(unit, spawn_point)
end

--- Iterates over unit definitions and calls CharacterManager
function TacticsEngine:spawn_units(units: {unit_spawn_data.UnitSpawnData}, side: battle_unit.Side): {battle_unit.BattleUnit}
    local spawned_units: {battle_unit.BattleUnit} = {}
    local char_man = self.character_manager
    local player_roster = char_man:get_player_roster()
    -- this will duplicate players if multiple roster spawns are made
    local roster_count = 1

    for _, spawn_data in ipairs(units) do
        local labels = {spawn_data.tile}
        local spawn_points = self.battle_map:get_tiles_by_label(spawn_data.tile)
        for _,spawn_point in ipairs(spawn_points) do
            local character: Character

            local character_source = spawn_data.character_source
            if character_source is unit_spawn_data.character_source.CharacterTemplateSource then
                character = char_man:generate_character(character_source.template)
                char_man:persist_player(character)
            elseif character_source is unit_spawn_data.character_source.PlayerRosterSource then
                if player_roster[roster_count] ~= nil then
                    character = player_roster[roster_count]
                    roster_count = roster_count + 1
                end
            else
                error()
            end
            local unit = battle_unit.spawn_unit(character, spawn_point, labels, side, spawn_data.ai)
            
            self:spawn_unit(unit, spawn_point)
            pt.add(spawned_units, unit)
        end
    end
    return spawned_units
end

function TacticsEngine:spawn_all(
    players: {unit_spawn_data.UnitSpawnData},
    enemies: {unit_spawn_data.UnitSpawnData},
    neutral: {unit_spawn_data.UnitSpawnData},
    animation: unit_spawn_data.UnitSpawnAnimation
)
    local spawned: {battle_unit.BattleUnit} = {}
    lists.add_all(spawned, self:spawn_units(players or {}, "player"))
    lists.add_all(spawned, self:spawn_units(enemies or {}, "enemy"))
    lists.add_all(spawned, self:spawn_units(neutral or {}, "neutral"))

    if animation ~= nil and #spawned > 0 then
        local max_offset = 0
        for _,unit in ipairs(spawned) do
            local offset: integer
            if animation == "from_north" then
                offset = unit.tile.y + 1
            elseif animation == "from_south" then
                offset = MAP_HEIGHT - unit.tile.y
            elseif animation == "from_east" then
                offset = MAP_WIDTH - unit.tile.x
            elseif animation == "from_west" then
                offset = unit.tile.x + 1
            else
                error()
            end
            if offset > max_offset then
                max_offset = offset 
            end
        end

        local offset_point: Point
        if animation == "from_north" then
            offset_point = Point.of(0,-max_offset)
        elseif animation == "from_south" then
            offset_point = Point.of(0,max_offset)
        elseif animation == "from_east" then
            offset_point = Point.of(max_offset,0)
        elseif animation == "from_west" then
            offset_point = Point.of(-max_offset,0)
        else
            error()
        end

        local path = { offset_point * TILE_SIZE, Point.of(0,0) }

        self.task_manager:start_routine(function()
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
        end)
    end
end

-- handlers

function TacticsEngine:handle_move_unit(ctx: MenuContext)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local path = ctx.destination.path

    self.battle_is_blocked = true
    self.task_manager:start_routine(function()
        if #path > 1 then
            local animation = self.animation_manager:create_walk_animation(to_tile_path(path))
            unit.animation_data = animation
            LOG.debug("Animating!", animation.playing)
            while animation.playing do
                pt.yield()
            end
        end

        self.battle_map:move_unit(unit, destination)
        unit.has_acted = true

        self.battle_is_blocked = false
        unit.animation_data = self.animation_manager:create_idle_animation()
        self.event_writer:emit("TACTICS_UNIT_END_ACTION", {})
    end)
end

function TacticsEngine:handle_move_and_attack(ctx: MenuContext)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local path = ctx.destination.path
    local target = ctx.target_unit.unit

    self.battle_is_blocked = true
    self.task_manager:start_routine(function()
        if #path > 1 then
            local animation = self.animation_manager:create_walk_animation(to_tile_path(path))
            unit.animation_data = animation

            while animation.playing do
                pt.yield()
            end
        end

        self.battle_map:move_unit(unit, destination)
        self:do_combat(unit, target)
        unit.has_acted = true

        self.battle_is_blocked = false
        LOG.debug("unblocking battle")
        unit.animation_data = self.animation_manager:create_idle_animation()
        target.animation_data = self.animation_manager:create_idle_animation()
        self.event_writer:emit("TACTICS_UNIT_END_ACTION", {})
    end)
end

-- Combat

function TacticsEngine:apply_combat_step(step: combat_calculator.CombatResult.CombatStep)
    local attacker = step.attacker
    local defender = step.defender

    local direction = pt.atan2(
            defender.tile.x - attacker.tile.x,
            defender.tile.y - attacker.tile.y
    )

    local attack_animation = self.animation_manager:create_animation("BUMP", direction)
    attacker.animation_data = attack_animation
    if not step.is_hit then
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
        defender:take_damage(step.dmg)
        local hurt_animation = self.animation_manager:create_animation("HURT", direction + 0.5)
        defender.animation_data = hurt_animation

        while hurt_animation.playing do
            pt.yield()
        end
    end

    if not defender:is_alive() then
        self.battle_map:kill_unit(defender)
        self.event_writer:emit("TACTICS_UNIT_DEATH", {
            attacker = attacker,
            defender = defender,
        })
    end
end

function TacticsEngine:do_combat(attacker: BattleUnit, defender: BattleUnit)
    local combat_result: combat_calculator.CombatResult = combat_calculator.compute_combat(attacker, defender, self.battle_map)

    for i,combat_step in ipairs(combat_result.steps) do
        LOG.debug("Combat step: ",i)
        self:apply_combat_step(combat_step as combat_calculator.CombatResult.CombatStep)
    end
end

-- Turn flow

function TacticsEngine:refresh_all_units()
    self:refresh_units(fn_true)
end

function TacticsEngine:refresh_units(filter: function(BattleUnit): boolean)
    local units_to_refresh = self.battle_map:get_units(filter)

    for _,unit in ipairs(units_to_refresh) do
        unit.has_acted = false
    end
end

function TacticsEngine:is_blocked(): boolean
    return self.battle_is_blocked
end

-- legal tile getters

function TacticsEngine:tiles_with_distance_from_unit_attacks(ctx: MenuContext): array_2d.Array2D<MenuTileHighlight>
    local unit = ctx.acting_unit.unit
    local min_range, max_range = unit.character:get_weapon_range()

    local destination = ctx.destination.point
    local tiles_in_distance = self:find_tiles_with_distance_from_tile(destination.x, destination.y, min_range, max_range)

    local tiles: array_2d.Array2D<MenuTileHighlight> = array_2d.new(MAP_WIDTH, MAP_HEIGHT)

    tiles_in_distance:foreach(function(x: integer, y: integer, in_range: boolean)
            if in_range then
                tiles:set(x, y, { can_attack = true, valid_selection = true })
            end
    end)

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

function TacticsEngine:tiles_in_movement_and_attack_range(ctx: MenuContext): array_2d.Array2D<MenuTileHighlight>
    local unit = ctx.acting_unit.unit
    local min_range, max_range = unit.character:get_weapon_range()

    local reachable_tiles = pathfinding.find_reachable_tiles(self.battle_map, unit.tile.x, unit.tile.y, unit.side, unit.character.stats.movement)

    local tiles: array_2d.Array2D<MenuTileHighlight> = array_2d.new(MAP_WIDTH, MAP_HEIGHT)

    reachable_tiles:foreach(function(x: integer, y: integer, reachable: boolean)
        if reachable then
            local tile = tiles:get(x,y)
            if tile == nil then tile = {} end
            tile.reachable = true
            tile.valid_selection = true
            tiles:set(x, y, tile)
            local tiles_in_attack_range = self:find_tiles_with_distance_from_tile(x, y, min_range, max_range)

            tiles_in_attack_range:foreach(function(ax: integer, ay: integer, can_attack: boolean)
                    if can_attack then
                        local a_tile = tiles:get(ax,ay)
                        if a_tile == nil then a_tile = {} end
                        a_tile.can_attack = true
                        tiles:set(ax, ay, a_tile)
                    end
            end)
        end
    end)

    return tiles
end

function TacticsEngine:update()
    local all_players_acted = true

    local is_player = function(u: BattleUnit): boolean
        return u:is_player()
    end

    for _,unit in ipairs(self.battle_map:get_units(is_player)) do
        if not unit.has_acted then
            all_players_acted = false
        end
    end

    if self.is_player_turn and all_players_acted then
        self.event_writer:emit("TACTICS_FINISH_PLAYER_ACTIONS", {})
    end
end

return tactics_engine
