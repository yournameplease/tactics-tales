require("src/config")
require("src/debug")

require ("src/menu/types")
require ("src/menu/menu_manager")

require("src/util")
local Pathfinding = require("src/battle/pathfinding")
require("src/draw")
local CombatCalculator = require("src/battle/combat/combat_calculator")
require("src/systems/event_bus")
require("src/systems/tasks")
require("src/animation")
require("src/systems/service")
require("src/battle/battle_context")
require("src/systems/service/game_service_bundle")

require("src/battle/tactics/battle_unit")
require("src/menu/types")
require("src/menu/cursor/grid_cursor")

global type MenuContext
global type MenuCursor

local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_HEIGHT

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record TacticsEngine
    ctx: BattleContext

    battle_is_blocked: boolean
    is_player_turn: boolean

    -- sometimes the lsp complains if i don't do this
    -- doesn't seem consistent tho?        
    handle_move_unit: function(self, MenuContext)
    handle_move_and_attack: function(self, MenuContext)
    apply_combat_step: function(self, CombatStep)
    do_combat: function(self, BattleUnit, BattleUnit)
    refresh_all_units: function(self)
    refresh_units: function(self, function(BattleUnit): boolean)
    is_blocked: function(self): boolean
    validate_tile_is_in_unit_attack_range: function(self, GridMenuCursor<BattleContext>, MenuContext): boolean
    any_target_in_range: function(self, MenuContext): boolean
    tiles_with_distance_from_unit_attacks: function(self, MenuContext): Array2D<MenuTileHighlight>
    find_tiles_with_distance_from_tile: function(self, integer, integer, integer, integer): Array2D<boolean>
    tiles_in_movement_and_attack_range: function(self, MenuContext): Array2D<MenuTileHighlight>
    grid_selection_is_empty_or_acting_unit: function(self, GridMenuCursor<BattleContext>, MenuContext): boolean
    grid_selection_is_available_player: function(self, GridMenuCursor<BattleContext>): boolean
    update: function(self)
end

function TacticsEngine.new(ctx: BattleContext): TacticsEngine
    local self: TacticsEngine = setmetatable({
        ctx = ctx
    }, { __index = TacticsEngine })
    self.battle_is_blocked = false

    return self
end

-- handlers

function TacticsEngine:handle_move_unit(ctx: MenuContext)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local path = ctx.destination.path

    self.battle_is_blocked = true
    self.ctx.services.task_manager:start_routine(function()
        if #path > 1 then
            local animation = self.ctx.services.animation_manager:create_walk_animation(to_tile_path(path))
            unit.animation_data = animation
            LOG.debug("Animating!", animation.playing)
            while animation.playing do
                yield()
            end
        end

        self.ctx.battle_map:move_unit(unit, destination)
        unit.has_acted = true

        self.battle_is_blocked = false
        unit.animation_data = self.ctx.services.animation_manager:create_idle_animation()
        self.ctx.services.event_bus:emit("TACTICS_UNIT_END_ACTION")
    end)
end

function TacticsEngine:handle_move_and_attack(ctx: MenuContext)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local path = ctx.destination.path
    local target = ctx.target_unit.unit

    self.battle_is_blocked = true
    self.ctx.services.task_manager:start_routine(function()
        if #path > 1 then
            local animation = self.ctx.services.animation_manager:create_walk_animation(to_tile_path(path))
            unit.animation_data = animation

            while animation.playing do
                yield()
            end
        end

        self.ctx.battle_map:move_unit(unit, destination)
        self:do_combat(unit, target)
        unit.has_acted = true

        self.battle_is_blocked = false
        LOG.debug("unblocking battle")
        unit.animation_data = self.ctx.services.animation_manager:create_idle_animation()
        target.animation_data = self.ctx.services.animation_manager:create_idle_animation()
        self.ctx.services.event_bus:emit("TACTICS_UNIT_END_ACTION")
    end)
end

-- Combat

function TacticsEngine:apply_combat_step(step: CombatStep)
    local attacker = step.attacker
    local defender = step.defender

    local direction = atan2(
            defender.tile.x - attacker.tile.x,
            defender.tile.y - attacker.tile.y
    )

    local attack_animation = self.ctx.services.animation_manager:create_animation("BUMP", direction)
    attacker.animation_data = attack_animation
    if not step.is_hit then
        local dodge_animation = self.ctx.services.animation_manager:create_animation("DODGE", direction + 0.25)
        defender.animation_data = dodge_animation
        while dodge_animation.playing do
            yield()
        end
    end
    while attack_animation.playing do
        yield()
    end

    if step.is_hit then
        defender:take_damage(step.dmg)
        local hurt_animation = self.ctx.services.animation_manager:create_animation("HURT", direction + 0.5)
        defender.animation_data = hurt_animation

        while hurt_animation.playing do
            yield()
        end
    end

    if not defender:is_alive() then
        self.ctx.battle_map:kill_unit(defender)
    end
end

function TacticsEngine:do_combat(attacker: BattleUnit, defender: BattleUnit)
    local combat_result = CombatCalculator.compute_combat(attacker, defender, self.ctx.battle_map)

    for i,combat_step in ipairs(combat_result.steps) do
        LOG.debug("Combat step: ",i)
        self:apply_combat_step(combat_step)
    end
end

-- Turn flow

function TacticsEngine:refresh_all_units()
    self:refresh_units(fn_true)
end

function TacticsEngine:refresh_units(filter: function(BattleUnit): boolean)
    local units_to_refresh = self.ctx.battle_map:get_units(filter)

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

function TacticsEngine:validate_tile_is_in_unit_attack_range(selection: GridMenuCursor<BattleContext>, ctx: MenuContext): boolean
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local min_range, max_range = unit.character:get_weapon_range()

    local target_point = selection.point

    local target_unit = self.ctx.battle_map:get_at_tile(target_point)
    if target_unit == nil then return false end

    if target_unit.side == unit.side then return false end

    return self.ctx.battle_map:tile_has_distance_from_tile(target_point, destination, min_range, max_range)
end

function TacticsEngine:any_target_in_range(ctx: MenuContext): boolean
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    
    local units_in_range = self.ctx.battle_map:get_targets_in_range(unit.id, destination)
    return #units_in_range > 0
end

-- legal tile getters

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function TacticsEngine:tiles_with_distance_from_unit_attacks(ctx: MenuContext): Array2D<MenuTileHighlight>
    local unit = ctx.acting_unit.unit
    local min_range, max_range = unit.character:get_weapon_range()

    local destination = ctx.destination.point
    local tiles_in_distance = self:find_tiles_with_distance_from_tile(destination.x, destination.y, min_range, max_range)

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
    local min_range, max_range = unit.character:get_weapon_range()

    local reachable_tiles = Pathfinding.find_reachable_tiles(self.ctx.battle_map, unit.tile.x, unit.tile.y, unit.side, unit.character.stats.movement)

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

function TacticsEngine:grid_selection_is_empty_or_acting_unit(grid_selection: GridMenuCursor<BattleContext>, ctx: MenuContext): boolean
    local destination_unit = self.ctx.battle_map:get_at_tile(grid_selection.point)
    if destination_unit == nil then
        return true
    end
    local acting_unit = ctx.acting_unit.unit
    return destination_unit.id == acting_unit.id
end

function TacticsEngine:grid_selection_is_available_player(grid_selection: GridMenuCursor<BattleContext>): boolean
    local unit = self.ctx.battle_map:get_at_tile(grid_selection.point)

    if unit == nil then return false end
    if unit.side ~= SIDE_PLAYER then return false end
    if unit.has_acted then return false end

    return true
end


function TacticsEngine:update()
    local blocking_animation = false
    local all_players_acted = true

    for _,unit in ipairs(self.ctx.battle_map:get_all_units()) do
        -- if unit.animation_blocking then
        --     blocking_animation = true
        -- end
        if unit.side == SIDE_PLAYER and not unit.has_acted then
            all_players_acted = false
        end
    end

    if blocking_animation then return end
    if self.is_player_turn and all_players_acted then
        self.ctx.services.event_bus:emit("TACTICS_END_PLAYER_TURN")
    end
end

return TacticsEngine
