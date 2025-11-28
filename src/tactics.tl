local CONFIG = require("src/config")
local LOG = require("src/debug")

require("src/util")
require("src/tiles")
require("src/draw")
require("src/combat/combat_calculator")
local BattleUnit = require("src/tactics/battle_unit")

local COLOR_MENU_PRIMARY = 32
local COLOR_MENU_SECONDARY = 7
local COLOR_MENU_TEXT = 7
local COLOR_MENU_HIGHLIGHT = 6
local COLOR_MENU_HIGHLIGHT_TEXT = 32

local MAP_OFFSET_X = 154
local MAP_OFFSET_Y = 11
local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_HEIGHT
local TILE_WIDTH = CONFIG.TILE_WIDTH
local TILE_HEIGHT = CONFIG.TILE_HEIGHT
local WALL_HEIGHT = CONFIG.WALL_HEIGHT
local UNIT_OFFSET_X = 1
local UNIT_OFFSET_Y = -3
local CURSOR_SPRITE = 8

local TEXT_HEIGHT = 7

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record TacticsEngine
    tile_manager: TileManager
    battle_state: BattleState
    combat_calculator: CombatCalculator
    battle_is_blocked: boolean
end


function TacticsEngine.new(battle_state: BattleState, tile_manager: TileManager): TacticsEngine
    local self: TacticsEngine = setmetatable({}, { __index = TacticsEngine })
    self.battle_is_blocked = false
    self.battle_state = battle_state
    self.tile_manager = tile_manager
    self.combat_calculator = CombatCalculator.new(tile_manager)
    BUS.on("MOVE_AND_WAIT", function(ctx)
        self:handle_move_unit(ctx)
    end)
    BUS.on("MOVE_AND_ATTACK", function(ctx)
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
            defender.x - attacker.x,
            defender.y - attacker.y
    )

    attacker:start_animation("BUMP", direction)
    if not step.is_hit then
        defender:start_animation("DODGE", direction + 0.25)
    end
    while attacker.animation_blocking or defender.animation_blocking do
        yield()
    end

    if step.is_hit then
        defender:take_damage(step.dmg)
        defender:start_animation("HURT", direction + 0.5)
    end

    while defender.animation_blocking do
        yield()
    end

    if not defender:is_alive() then
        self.battle_state:kill_unit(defender)
    end
end

function TacticsEngine:do_combat(attacker: BattleUnit, defender: BattleUnit)
    local combat_result = combat_calculator.compute_combat(attacker, defender)

    for i,combat_step in ipairs(combat_result.steps) do
        LOG.debug("Combat step: ",i)
        self:apply_combat_step(combat_step)
    end
end

-- Turn flow

function Battle:refresh_units(filter)
    local units_to_refresh = self.battle_state:get_units(filter)

    for unit in all(units_to_refresh) do
        unit.has_acted = false
    end
end

function Battle:is_blocked()
    return self.battle_is_blocked
end



-- step data helpers

function Battle:get_unit_from_step(ctx, step)
    return self.battle_state:get_unit_by_id(ctx[step].unit_id)
end

-- unit filters

global function unit_is_player(unit: BattleUnit): boolean
    return unit.side == SIDE_PLAYER
end

global function unit_is_enemy(unit: BattleUnit): boolean
    return unit.side == SIDE_ENEMY
end

-- validators

function Battle:validate_tile_is_in_unit_attack_range(selection, ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range
    local destination = ctx["destination"]
    local unit_x = destination.x
    local unit_y = destination.y
    local target_x = selection.x
    local target_y = selection.y

    local target_unit = self.battle_state:get_unit_at_coordinates(target_x, target_y)
    if target_unit == nil then return false end

    if target_unit.side == unit.side then return false end

    return self.battle_state:tile_has_distance_from_tile(target.tile, unit_x, unit_y, min_distance, max_distance)
end

function Battle:any_target_in_range(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local destination = ctx["destination"]
    local unit_x = destination.x
    local unit_y = destination.y

    local units_in_range = self.battle_state:get_targets_in_range(unit.id, unit_x, unit_y)
    return #units_in_range > 0
end

-- legal tile getters

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function Battle:tiles_with_distance_from_unit_attacks(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range

    local destination = ctx["destination"]
    local dest_x = destination.x
    local dest_y = destination.y
    local tiles_in_distance =  self:find_tiles_with_distance_from_tile(dest_x, dest_y, min_distance, max_distance)

    local tiles = Array2D.new(MAP_WIDTH, MAP_HEIGHT)

    for x, r in pairs(tiles_in_distance) do
        for y, in_range in pairs(r) do
            if in_range then
                local tile = tiles:get(x,y)
                if tile == nil then tile = {} end
                tile.can_attack = true
                tile.valid_selection = true
                tiles:set(x, y, tile)
            end
        end
    end

    return tiles
end

-- @return  { [x][y] = bool }
function Battle:find_tiles_with_distance_from_tile(tile_x, tile_y, min_distance, max_distance)
    max_distance = max_distance or min_distance

    local reachable = {}
    for x=-max_distance,max_distance do
        local map_x = x + tile_x
        if map_x >= 0 and map_x < MAP_WIDTH then
            local abs_x = abs(x)
            local min_y_abs = max(0, min_distance-abs_x)
            local max_y_abs = max_distance-abs_x

            if max_y_abs >= min_y_abs then
                reachable[map_x] = {}
                for y=-max_y_abs,-min_y_abs do
                    local map_y = y + tile_y
                    if map_y >= 0 and map_y < MAP_HEIGHT then
                        reachable[map_x][map_y] = true
                    end
                end
                for y=min_y_abs,max_y_abs do
                    local map_y = y + tile_y
                    if map_y >= 0 and map_y < MAP_HEIGHT then
                        reachable[map_x][map_y] = true
                    end
                end
            end
        end
    end

    return reachable

end

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function Battle:tiles_in_movement_and_attack_range(ctx)
    local unit = self.battle_state:get_unit_by_id(ctx["acting_unit"].unit_id)
    local min_range = unit.weapon.min_range
    local max_range = unit.weapon.max_range

    local reachable_tiles = self.tile_manager:find_reachable_tiles(unit.x, unit.y, unit.side, unit.movement)

    local tiles = Array2D.new(MAP_WIDTH, MAP_HEIGHT)


    for x, r in pairs(reachable_tiles) do
        for y, reachable  in pairs(r) do
            if reachable then
                local tile = tiles:get(x,y)
                if tile == nil then tile = {} end
                tile.reachable = true
                tile.valid_selection = true
                tiles:set(x, y, tile)
                local tiles_in_attack_range = self:find_tiles_with_distance_from_tile(x, y, min_range, max_range)

                for ax, ar in pairs(tiles_in_attack_range) do
                    for ay, can_attack  in pairs(ar) do
                        if can_attack then
                            local a_tile = tiles:get(ax,ay)
                            if a_tile == nil then a_tile = {} end
                            a_tile.can_attack = true
                            tiles:set(ax, ay, a_tile)
                        end
                    end
                end
            end
        end
    end

    return tiles
end

function Battle:grid_selection_is_empty_or_acting_unit(grid_selection, ctx)
    local destination_unit = self.battle_state:get_unit_at_coordinates(grid_selection.x, grid_selection.y)
    if destination_unit == nil then
        return true
    end
    local acting_unit = Battle:get_unit_by_id(ctx["acting_unit"].unit_id)
    return destination_unit.id == acting_unit.id
end

function Battle:selected_empty_tile_mapper (active_cursor)
    local selected_unit = self.battle_state:get_unit_at_coordinates(active_cursor.x, active_cursor.y)
    if selected_unit == nil then
        return true, {x = active_cursor.x, y = active_cursor.y}
    end
    return false, nil
end

-- handlers

function Battle:handle_move_unit(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local x = ctx["destination"].x
    local y = ctx["destination"].y
    local path = ctx["destination"].path

    self.battle_is_blocked = true
    start_routine(function()
        unit:start_walk_animation(path)
        while unit.animation_blocking do
            yield()
        end
        unit:end_animation()

        self.battle_state:move_unit(unit, x, y)
        unit.has_acted = true

        MENU_MANAGER.set_menu("MENU_PLAYER_TURN")
        self.battle_is_blocked = false
    end)
end

function Battle:handle_move_and_attack(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local x = ctx["destination"].x
    local y = ctx["destination"].y
    local path = ctx["destination"].path
    local target = self:get_unit_from_step(ctx, "target")

    self.battle_is_blocked = true
    start_routine(function()
        unit:start_walk_animation(path)
        while unit.animation_blocking do
            yield()
        end
        unit:end_animation()

        self.battle_state:move_unit(unit, x, y)
        do_combat(unit, target, self.battle_state)
        unit.has_acted = true

        MENU_MANAGER.set_menu("MENU_PLAYER_TURN")
        self.battle_is_blocked = false
        LOG.debug("unblockiung battle")
    end)
end

function Battle:grid_selection_is_available_player(grid_selection)
    local unit = self.battle_state:get_unit_at_coordinates(grid_selection.x, grid_selection.y)

    if unit == nil then return false end
    if unit.side ~= SIDE_PLAYER then return false end
    if unit.has_acted then return false end

    return true
end


function Battle:update()
    local blocking_animation = false
    local all_players_acted = true

    for unit in all(self.battle_state:get_all_units()) do
        unit:update_animation()
        if unit.animation_blocking then
            blocking_animation = true
        end
        if unit.side == SIDE_PLAYER and not unit.has_acted then
            all_players_acted = false
        end
    end

    if blocking_animation then return end
    if all_players_acted then
        BUS.emit("TACTICS_END_PLAYER_TURN")
    end
end




function Battle:draw_tactics_debug()
    print(MENU_MANAGER.menu_state.menu_id, 3 + 3, 3 + 3, 6)
    print(MENU_MANAGER.menu_state.menu_step, 3 + 3, 11 + 3, 6)
    print("x: "..(MENU_MANAGER.menu_selection.x or "nil"), 3 + 3, 19 + 3, 6)
    print("y: "..(MENU_MANAGER.menu_selection.y or "nil"), 3 + 3, 27 + 3, 6)
    print("i: "..(MENU_MANAGER.menu_selection.i or "nil"), 3 + 3, 35 + 3, 6)

    print("ABCDEFGHIJKLMNOPQRSTUVWXYZABC", 4, 50, 6)
end

return Battle
