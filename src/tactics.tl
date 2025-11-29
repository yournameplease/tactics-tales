local CONFIG = require("src/config")
local LOG = require("src/debug")

require("src/util")
require("src/tiles")
require("src/draw")
require("src/combat/combat_calculator")
require("src/systems/event_bus")
require("src/systems/tasks")
require("src/menu_manager")

require("src/tactics/battle_unit")

local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_HEIGHT

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record TacticsEngine
    tile_manager: TileManager
    battle_state: BattleState
    combat_calculator: CombatCalculator
    event_bus: EventBus
    task_manager: TaskManager

    battle_is_blocked: boolean
end


function TacticsEngine.new(battle_state: BattleState, tile_manager: TileManager, event_bus: EventBus): TacticsEngine
    local self: TacticsEngine = setmetatable({}, { __index = TacticsEngine })
    self.battle_is_blocked = false
    self.battle_state = battle_state
    self.tile_manager = tile_manager
    self.combat_calculator = CombatCalculator.new(tile_manager)
    self.event_bus = event_bus

    self.event_bus:on("MOVE_AND_WAIT", function(ctx: MenuContext)
        self:handle_move_unit(ctx)
    end)
    self.event_bus:on("MOVE_AND_ATTACK", function(ctx: MenuContext)
        self:handle_move_and_attack(ctx)
    end)
    LOG.debug("battle new", #self.battle_state.units_by_id)
    return self
end

-- Combat

function TacticsEngine:apply_combat_step(step: CombatStep)
    local attacker = step.attacker
    local defender = step.defender

    local direction = atan2(
            defender.tile.x - attacker.tile.x,
            defender.tile.y - attacker.tile.y
    )

    -- attacker:start_animation("BUMP", direction)
    if not step.is_hit then
    --     defender:start_animation("DODGE", direction + 0.25)
    end
    while attacker.character.animation_blocking or defender.character.animation_blocking do
        yield()
    end

    if step.is_hit then
        defender:take_damage(step.dmg)
    --     defender:start_animation("HURT", direction + 0.5)
    end

    while defender.character.animation_blocking do
        yield()
    end

    if not defender:is_alive() then
        self.battle_state:kill_unit(defender)
    end
end

function TacticsEngine:do_combat(attacker: BattleUnit, defender: BattleUnit)
    local combat_result = self.combat_calculator:compute_combat(attacker, defender)

    for i,combat_step in ipairs(combat_result.steps) do
        LOG.debug("Combat step: ",i)
        self:apply_combat_step(combat_step)
    end
end

-- Turn flow

function TacticsEngine:refresh_units(filter: function(BattleUnit): boolean)
    local units_to_refresh = self.battle_state:get_units(filter)

    for _,unit in ipairs(units_to_refresh) do
        unit.has_acted = false
    end
end

function TacticsEngine:is_blocked(): boolean
    return self.battle_is_blocked
end

-- unit filters

global function unit_is_player(unit: BattleUnit): boolean
    return unit.side == SIDE_PLAYER
end

global function unit_is_enemy(unit: BattleUnit): boolean
    return unit.side == SIDE_ENEMY
end

-- validators

function TacticsEngine:validate_tile_is_in_unit_attack_range(selection: MenuSelection, ctx: MenuContext): boolean
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range

    if selection is GridMenuSelection then
        local target_point = selection.point

        local target_unit = self.battle_state:get_at_tile(destination)
        if target_unit == nil then return false end

        if target_unit.side == unit.side then return false end

        return self.battle_state:tile_has_distance_from_tile(target_point, destination, min_distance, max_distance)
    end
    return false
end

function TacticsEngine:any_target_in_range(ctx: MenuContext): boolean
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    
    local units_in_range = self.battle_state:get_targets_in_range(unit.id, destination)
    return #units_in_range > 0
end

-- legal tile getters

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function TacticsEngine:tiles_with_distance_from_unit_attacks(ctx: MenuContext): Array2D<MenuTileHighlight>
    local unit = ctx.acting_unit.unit
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range

    local destination = ctx.destination.point
    local tiles_in_distance = self:find_tiles_with_distance_from_tile(destination.x, destination.y, min_distance, max_distance)

    local tiles: Array2D<MenuTileHighlight> = Array2D.new(MAP_WIDTH, MAP_HEIGHT)

    tiles_in_distance:foreach(function(x: integer, y: integer, in_range: boolean)
            if in_range then
                tiles:set(x, y, { can_attack = true, valid_selection = true })
            end
    end)

    return tiles
end

-- @return  { [x][y] = bool }
function TacticsEngine:find_tiles_with_distance_from_tile(tile_x: integer, tile_y: integer, min_distance: integer, max_distance: integer): Array2D<boolean>
    max_distance = max_distance or min_distance

    local reachable = Array2D.new(MAP_WIDTH, MAP_HEIGHT, false)
    for x=-max_distance,max_distance do
        local map_x = x + tile_x
        if map_x >= 0 and map_x < MAP_WIDTH then
            local abs_x = abs(x)
            local min_y_abs = max(0, min_distance-abs_x)
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

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function TacticsEngine:tiles_in_movement_and_attack_range(ctx: MenuContext): Array2D<MenuTileHighlight>
    local unit = ctx.acting_unit.unit
    local min_range = unit.weapon.min_range
    local max_range = unit.weapon.max_range

    local reachable_tiles = self.tile_manager:find_reachable_tiles(unit.tile.x, unit.tile.y, unit.side, unit.character.stats.movement)

    local tiles: Array2D<MenuTileHighlight> = Array2D.new(MAP_WIDTH, MAP_HEIGHT)

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

function TacticsEngine:grid_selection_is_empty_or_acting_unit(grid_selection: MenuSelection, ctx: MenuContext): boolean
    assert(grid_selection is GridMenuSelection)
    local destination_unit = self.battle_state:get_at_tile(grid_selection.point)
    if destination_unit == nil then
        return true
    end
    local acting_unit = ctx.acting_unit.unit
    return destination_unit.id == acting_unit.id
end

-- handlers

function TacticsEngine:handle_move_unit(ctx: MenuContext)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local path = ctx.destination.path

    self.battle_is_blocked = true
    self.task_manager:start_routine(function()
        unit.character:start_walk_animation(path)
        while unit.character.animation_blocking do
            yield()
        end
        unit.character:end_animation()

        self.battle_state:move_unit(unit, destination)
        unit.has_acted = true

        self.event_bus:emit("TACTICS_UNIT_END_ACTION")
        self.battle_is_blocked = false
    end)
end

function TacticsEngine:handle_move_and_attack(ctx: MenuContext)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local path = ctx.destination.path
    local target = ctx.target_unit.unit

    self.battle_is_blocked = true
    self.task_manager:start_routine(function()
        unit.character:start_walk_animation(path)
        while unit.character.animation_blocking do
            yield()
        end
        unit.character:end_animation()

        self.battle_state:move_unit(unit, destination)
        self:do_combat(unit, target)
        unit.has_acted = true

        self.event_bus:emit("TACTICS_UNIT_END_ACTION")
        self.battle_is_blocked = false
        LOG.debug("unblockiung battle")
    end)
end

function TacticsEngine:grid_selection_is_available_player(grid_selection: MenuSelection): boolean
    assert(grid_selection is GridMenuSelection)
    local unit = self.battle_state:get_at_tile(grid_selection.point)

    if unit == nil then return false end
    if unit.side ~= SIDE_PLAYER then return false end
    if unit.has_acted then return false end

    return true
end


function TacticsEngine:update()
    local blocking_animation = false
    local all_players_acted = true

    for _,unit in ipairs(self.battle_state:get_all_units()) do
        if unit.character.animation_blocking then
            blocking_animation = true
        end
        if unit.side == SIDE_PLAYER and not unit.has_acted then
            all_players_acted = false
        end
    end

    if blocking_animation then return end
    if all_players_acted then
        self.event_bus:emit("TACTICS_END_PLAYER_TURN")
    end
end

return TacticsEngine
