---@brief
--- Manages the menu system used during a battle.
--- Defines the structure and flow of in-battle menus, such as the
--- unit action menu and deployment screen.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local list = require("src.tactics.menu.cursor.nested.list")
local grid = require("src.tactics.menu.cursor.nested.grid")
local button = require("src.tactics.menu.cursor.button")
local point = require("src.tactics.util.point")
local pathfinding = require("src.tactics.battle.pathfinding")

---@class BattleMenuManager : MenuManager

local BattleMenuManager = {}
BattleMenuManager.__index = BattleMenuManager



---@param point Point
---@param map BattleMap
---@param ctx BattleMainMenuContext
---@return boolean
local function point_is_empty_or_acting_unit(point, map, ctx)
    local destination_unit = map:get_at_tile(point)
    if destination_unit == nil then
        return true
    end
    local acting_unit = ctx.acting_unit.unit
    return destination_unit.id == acting_unit.id
end

---@param unit BattleUnit
---@return boolean
local function unit_is_available_player(unit)
    if not unit:is_player() then return false end
    if unit.has_acted then return false end
    return true
end

---@param point Point
---@param map BattleMap
---@return boolean
local function point_is_available_player(point, map)
    local unit = map:get_at_tile(point)
    if unit == nil then return false end
    if not unit:is_player() then return false end
    if unit.has_acted then return false end
    return true
end

---@param point Point
---@param map BattleMap
---@return boolean
local function point_is_enemy_unit(point, map)
    local unit = map:get_at_tile(point)
    if unit == nil then return false end
    return unit:is_enemy()
end

---@param point Point
---@param map BattleMap
---@return boolean
local function point_is_any_unit(point, map)
    local unit = map:get_at_tile(point)
    return unit ~= nil
end

---@param map BattleMap
---@param ctx BattleMainMenuContext
---@return boolean
local function any_target_in_range(map, ctx)
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    local units_in_range = map:get_targets_in_range(unit.id, destination)
    return #units_in_range > 0
end

---@param map BattleMap
---@param unit BattleUnit
---@param unit_position Point
---@param target_point Point
---@return boolean
local function validate_tile_is_in_unit_attack_range(map, unit, unit_position, target_point)
    local targeting = unit.character:get_weapon_targeting()
    local target_unit = map:get_at_tile(target_point)
    if target_unit == nil then return false end
    if target_unit.side ~= "enemy" then return false end
    return targeting.is_target_valid(unit_position, target_point, map, unit.side)
end

---@class BattlePreparationsContext : MenuContext
---@field swap_source Point

---@param msb BattleMenuContext
---@param _ctx BattleMainMenuContext
---@return userdata_2d
local function get_deployment_tiles(msb, _ctx)
    return msb.battle_map:get_tiles_userdata_by(
        "u8",
        function(p)
            return msb.battle_map:tile_has_label(p, msb.deployment_tiles_tag)
                and HIGHLIGHT.IS_VALID
                or 0
        end)
end

---@param msb BattleMenuContext
---@param _ctx BattleMainMenuContext
---@return userdata_2d
local function get_players_to_act_tiles(msb, _ctx)
    return msb.battle_map:get_tiles_userdata_by(
        "u8",
        function(p)
            local unit = msb.battle_map:get_at_tile(p)
            return (unit and unit:is_player() and not unit.has_acted)
                and HIGHLIGHT.IS_VALID
                or 0
        end)
end

---@param msb BattleMenuContext
---@param ctx BattleMainMenuContext
---@return userdata_2d
local function get_tile_highlights_in_move_and_attack_range(msb, ctx)
    return msb.tactics_engine:get_valid_tiles_for_unit(ctx.acting_unit.unit)
end

---@param target_point Point
---@param valid_tiles userdata_2d
---@param acting_unit BattleUnit
---@param map BattleMap
---@return InteractionHook|nil
local function get_single_unit_interaction(target_point, valid_tiles, acting_unit, map)
    local target_unit = map:get_at_tile(target_point)
    if target_unit == nil then return nil end
    local neighbors = {
        point.of(target_point.x - 1, target_point.y),
        point.of(target_point.x + 1, target_point.y),
        point.of(target_point.x, target_point.y - 1),
        point.of(target_point.x, target_point.y + 1),
    }
    local found = nil
    for _, p in ipairs(neighbors) do
        local tile_data = valid_tiles:get(p.x, p.y)
        if tile_data ~= nil and tile_data & 0x1 ~= 0 then
            local occupant = map:get_at_tile(p)
            if occupant == nil or occupant.id == acting_unit.id then
                for _, interaction in ipairs(map:get_nearby_interactions(p)) do
                    if interaction.target_unit ~= nil
                        and interaction.target_unit.id == target_unit.id
                    then
                        if found ~= nil then return nil end
                        found = interaction
                    end
                end
            end
        end
    end
    return found
end

--- Return a predicate matching available player units whose tile is after point.
---@param point Point
---@return fun(unit: BattleUnit): boolean
local function is_acting_unit_after(point)
    return function(unit)
        return unit_is_available_player(unit) and unit.tile > point
    end
end

--- Return a predicate matching available player units whose tile is before point.
---@param point Point
---@return fun(unit: BattleUnit): boolean
local function is_acting_unit_before(point)
    return function(unit)
        return unit_is_available_player(unit) and unit.tile < point
    end
end

---@type table<string, MenuHandler<BattleMenuContext, BattlePreparationsContext>>
local DEPLOYMENT_HANDLERS = {}

---@param services BattleMenuContext
---@param _session_context BattlePreparationsContext
---@param value any
---@return nil
function DEPLOYMENT_HANDLERS.mark_unit(services, _session_context, value)
    services.tactics_engine:handle_mark_unit(value.point)
    return nil
end

---@param services BattleMenuContext
---@param session_context BattlePreparationsContext
---@param value any
---@return nil
function DEPLOYMENT_HANDLERS.select_swap_unit(services, session_context, value)
    session_context.swap_source = value.point
    services.tactics_engine.active_point = value.point
    return nil
end

---@param services BattleMenuContext
---@param session_context BattlePreparationsContext
---@param value any
---@return MenuHandlerPostHandling
function DEPLOYMENT_HANDLERS.swap_units(services, session_context, value)
    services.tactics_engine:handle_swap_unit(
        session_context.swap_source,
        value.point
    )
    services.tactics_engine.active_point = value.point
    session_context.swap_source = nil
    return menu_manager.menu_handler.then_recompute()
end

---@param services BattleMenuContext
---@param _session_context BattlePreparationsContext
---@param _value any
---@return nil
function DEPLOYMENT_HANDLERS.start_battle(services, _session_context, _value)
    services.handle_start_battle()
    return nil
end

---@param _services BattleMenuContext
---@param _session_context BattlePreparationsContext
---@param _value any
---@return MenuHandlerPostHandling
function DEPLOYMENT_HANDLERS.navigate_to_deployment_menu(_services, _session_context, _value)
    return menu_manager.menu_handler.then_navigate("DEPLOYMENT_MENU")
end

---@type table<string, MenuHandler<BattleMenuContext, BattleMainMenuContext>>
local PLAYER_TURN_HANDLERS = {}

---@param services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.mark_unit(services, _session_context, value)
    services.tactics_engine:handle_mark_unit(value.point)
    return nil
end

---@param services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param _value any
---@return nil
function PLAYER_TURN_HANDLERS.end_turn(services, _session_context, _value)
    services.handle_end_turn()
    return nil
end

---@param services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param value any
---@return MenuHandlerPostHandling?
function PLAYER_TURN_HANDLERS.cycle_next_unit(services, _session_context, value)
    local pt_val = value.point
    local next_unit = nil

    log.debug("CYCLING NEXT UNIT")
    local units_after = services.battle_map:get_units(is_acting_unit_after(pt_val))
    for _, u in ipairs(units_after) do
        if not next_unit or u.tile < next_unit.tile then
            next_unit = u
        end
    end
    if next_unit then
        return menu_manager.menu_handler.then_move_cursor(next_unit.tile)
    end

    local units_before = services.battle_map:get_units(is_acting_unit_before(pt_val))
    for _, u in ipairs(units_before) do
        if not next_unit or u.tile < next_unit.tile then
            next_unit = u
        end
    end
    if next_unit then
        return menu_manager.menu_handler.then_move_cursor(next_unit.tile)
    end

    return nil
end

---@param services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param value any
---@return MenuHandlerPostHandling?
function PLAYER_TURN_HANDLERS.cycle_previous_unit(services, _session_context, value)
    local pt_val = value.point
    local previous_unit = nil

    log.debug("CYCLING PREVIOUS UNIT")
    local units_before = services.battle_map:get_units(is_acting_unit_before(pt_val))
    for _, u in ipairs(units_before) do
        if not previous_unit or u.tile > previous_unit.tile then
            previous_unit = u
        end
    end
    if previous_unit then
        return menu_manager.menu_handler.then_move_cursor(previous_unit.tile)
    end

    local units_after = services.battle_map:get_units(is_acting_unit_after(pt_val))
    for _, u in ipairs(units_after) do
        if not previous_unit or u.tile > previous_unit.tile then
            previous_unit = u
        end
    end
    if previous_unit then
        return menu_manager.menu_handler.then_move_cursor(previous_unit.tile)
    end

    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.select_acting_unit(services, session_context, value)
    local unit = services.battle_map:get_at_tile(value.point)
    assert(unit, "select_acting_unit: no unit at tile")
    session_context.acting_unit = {
        unit = unit,
        point = unit.tile:copy(),
    }
    services.tactics_engine.active_point = value.point
    return nil
end

---@param services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param _value any
---@return nil
function PLAYER_TURN_HANDLERS.unmark_all_units(services, _session_context, _value)
    services.tactics_engine:handle_unmark_all_units()
    return nil
end

---@param services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param _value any
---@return nil
function PLAYER_TURN_HANDLERS.mark_all_units(services, _session_context, _value)
    services.tactics_engine:handle_mark_all_units()
    return nil
end

---@param _services BattleMenuContext
---@param _session_context BattleMainMenuContext
---@param _value any
---@return MenuHandlerPostHandling
function PLAYER_TURN_HANDLERS.navigate_to_turn_menu(_services, _session_context, _value)
    return menu_manager.menu_handler.then_navigate("TURN_MENU")
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
function PLAYER_TURN_HANDLERS.cycle_attack_position(services, session_context, _value)
    local points = session_context.valid_attack_points
    if not points or #points < 2 then return nil end
    local current = session_context.destination.point
    local current_index = 1
    for i, p in ipairs(points) do
        if p == current then
            current_index = i
            break
        end
    end
    local next_point = points[(current_index % #points) + 1]
    services.tactics_engine:jump_unit_to_point(session_context.acting_unit.unit, next_point)
    session_context.destination.point = next_point
    services.tactics_engine.active_point = next_point
    return menu_manager.menu_handler.then_recompute()
end

---@param _services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.store_selected_skill(_services, session_context, value)
    session_context.selected_skill_id = value
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.use_skill_at_tile(services, session_context, value)
    services.tactics_engine:handle_skill(
        session_context.acting_unit.unit,
        session_context.selected_skill_id,
        value.point
    )
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param _value any
---@return nil
function PLAYER_TURN_HANDLERS.wait_acting_unit(services, session_context, _value)
    services.tactics_engine:finish_unit_action(session_context.acting_unit.unit)
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.move_acting_unit(services, session_context, value)
    session_context.destination = {
        point = value.point,
        path = value.path,
    }
    services.tactics_engine:handle_move_unit(
        session_context.acting_unit.unit,
        session_context.destination.point,
        session_context.destination.path
    )
    services.tactics_engine.active_point = value.point
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param _value any
---@return nil
function PLAYER_TURN_HANDLERS.unmove_acting_unit(services, session_context, _value)
    services.tactics_engine:jump_unit_to_point(
        session_context.acting_unit.unit,
        session_context.acting_unit.point
    )
    services.tactics_engine.active_point = session_context.acting_unit.point
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param _data any
---@param value NestedGridValue
---@return MenuHandlerPostHandling?
function PLAYER_TURN_HANDLERS.trim_attack_path(services, session_context, _data, value)
    if not point_is_enemy_unit(value.point, services.battle_map) then
        return nil
    end
    local acting_unit = session_context.acting_unit
    if not acting_unit then
        return nil
    end
    local unit = acting_unit.unit
    local targeting = unit.character:get_weapon_targeting()
    local valid_tiles = services.tactics_engine:get_valid_tiles_for_unit(unit)

    for i = #value.path, 1, -1 do
        if targeting.is_target_valid(value.path[i], value.point, services.battle_map, unit.side)
            and services.battle_map:get_at_tile(value.path[i]) == nil
        then
            local trimmed_path = {}
            for j = 1, i do trimmed_path[j] = value.path[j] end
            return menu_manager.menu_handler.then_deserialize({ _grid_path = trimmed_path })
        end
    end

    local valid_attack_points = {}
    for x = 0, services.battle_map.width - 1 do
        for y = 0, services.battle_map.height - 1 do
            local tile_data = valid_tiles:get(x, y)
            if tile_data ~= nil and tile_data & 0x1 ~= 0 then
                local p = point.of(x, y)
                local occupant = services.battle_map:get_at_tile(p)
                if (occupant == nil or occupant.id == unit.id)
                    and targeting.is_target_valid(p, value.point, services.battle_map, unit.side)
                then
                    table.insert(valid_attack_points, p)
                end
            end
        end
    end
    if #valid_attack_points == 0 then
        return nil
    end

    local cursor_point = value.path[#value.path]
    local destination_point = valid_attack_points[1]
    local best_dist = math.abs(destination_point.x - cursor_point.x) + math.abs(destination_point.y - cursor_point.y)
    for i = 2, #valid_attack_points do
        local p = valid_attack_points[i]
        local d = math.abs(p.x - cursor_point.x) + math.abs(p.y - cursor_point.y)
        if d < best_dist then
            best_dist = d
            destination_point = p
        end
    end
    local trimmed_path = pathfinding.extend_path_to_point(
        { acting_unit.point:copy() },
        destination_point,
        unit.character.stats.movement,
        valid_tiles
    )
    return menu_manager.menu_handler.then_deserialize({ _grid_path = trimmed_path })
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return MenuHandlerPostHandling?
function PLAYER_TURN_HANDLERS.move_and_store_attack_unit(services, session_context, value)
    local target_point = value.point
    local acting_unit = session_context.acting_unit.unit
    local targeting = acting_unit.character:get_weapon_targeting()
    local valid_tiles = services.tactics_engine:get_valid_tiles_for_unit(acting_unit)

    local valid_attack_points = {}
    for x = 0, services.battle_map.width - 1 do
        for y = 0, services.battle_map.height - 1 do
            local tile_data = valid_tiles:get(x, y)
            if tile_data ~= nil and tile_data & 0x1 ~= 0 then
                local p = point.of(x, y)
                local occupant = services.battle_map:get_at_tile(p)
                if (occupant == nil or occupant.id == acting_unit.id)
                    and targeting.is_target_valid(p, target_point, services.battle_map, acting_unit.side)
                then
                    table.insert(valid_attack_points, p)
                end
            end
        end
    end
    session_context.valid_attack_points = valid_attack_points

    if #valid_attack_points == 0 then
        return menu_manager.menu_handler.then_dont_navigate()
    end

    local trimmed_path = value.path
    local destination_point = trimmed_path[#trimmed_path]
    session_context.destination = {
        point = destination_point,
        path = trimmed_path,
    }
    services.tactics_engine:handle_move_unit(acting_unit, destination_point, trimmed_path)
    local move_target_unit = services.battle_map:get_at_tile(target_point)
    assert(move_target_unit, "move_and_store_attack_unit: no unit at target tile")
    session_context.target_unit = { unit = move_target_unit, point = target_point }
    services.tactics_engine.active_point = destination_point
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return MenuHandlerPostHandling?
function PLAYER_TURN_HANDLERS.move_and_store_interaction_unit(services, session_context, value)
    local target_point = value.point
    local acting_unit = session_context.acting_unit.unit
    local valid_tiles = services.tactics_engine:get_valid_tiles_for_unit(acting_unit)
    local neighbors = {
        point.of(target_point.x - 1, target_point.y),
        point.of(target_point.x + 1, target_point.y),
        point.of(target_point.x, target_point.y - 1),
        point.of(target_point.x, target_point.y + 1),
    }
    local dest_point = nil
    local interaction = nil
    local target_unit = services.battle_map:get_at_tile(target_point)
    assert(attack_target_unit, "move_and_store_interaction_unit: no unit at tile")
    for _, p in ipairs(neighbors) do
        local tile_data = valid_tiles:get(p.x, p.y)
        if tile_data ~= nil and tile_data & 0x1 ~= 0 then
            local occupant = services.battle_map:get_at_tile(p)
            if occupant == nil or occupant.id == acting_unit.id then
                for _, iact in ipairs(services.battle_map:get_nearby_interactions(p)) do
                    if iact.target_unit ~= nil and iact.target_unit.id == target_unit.id then
                        dest_point = p
                        interaction = iact
                        break
                    end
                end
            end
        end
        if dest_point then break end
    end
    if dest_point == nil then
        return menu_manager.menu_handler.then_dont_navigate()
    end
    local path = pathfinding.extend_path_to_point(
        { session_context.acting_unit.point:copy() },
        dest_point,
        acting_unit.character.stats.movement,
        valid_tiles
    )
    session_context.destination = { point = dest_point, path = path }
    session_context.stored_interaction = interaction
    services.tactics_engine:handle_move_unit(acting_unit, dest_point, path)
    services.tactics_engine.active_point = dest_point
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.store_attack_unit(services, session_context, value)
    local attack_target_unit = services.battle_map:get_at_tile(value.point)
    assert(attack_target_unit, "store_attack_unit: no unit at tile")
    session_context.target_unit = { unit = attack_target_unit, point = value.point }
    services.tactics_engine.active_point = value.point
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param _value any
---@return nil
function PLAYER_TURN_HANDLERS.attack_unit(services, session_context, _value)
    services.tactics_engine:handle_attack_unit(
        session_context.acting_unit.unit,
        session_context.target_unit.unit
    )
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param value any
---@return nil
function PLAYER_TURN_HANDLERS.attack_unit_at_tile(services, session_context, value)
    local target_unit = services.battle_map:get_at_tile(value.point)
    assert(target_unit, "attack_unit_at_tile: no unit at tile")
    services.tactics_engine:handle_attack_unit(
        session_context.acting_unit.unit,
        target_unit
    )
    return nil
end

---@param services BattleMenuContext
---@param session_context BattleMainMenuContext
---@param interaction InteractionHook
---@return nil
function PLAYER_TURN_HANDLERS.handle_interaction(services, session_context, interaction)
    session_context.selected_script = {
        script_id = interaction.script_id,
        target_unit = interaction.target_unit,
        target_tile = interaction.target_tile,
    }
    services.tactics_engine:handle_interaction(
        interaction.script_id,
        session_context.acting_unit.unit,
        interaction.target_unit,
        interaction.target_tile
    )
    return nil
end

---@param point Point
---@param msb BattleMenuContext
---@param _ctx any
---@return boolean
local function filter_available_player(point, msb, _ctx)
    return point_is_available_player(point, msb.battle_map)
end

---@param point Point
---@param msb BattleMenuContext
---@param _ctx any
---@return boolean
local function filter_any_unit(point, msb, _ctx)
    return point_is_any_unit(point, msb.battle_map)
end

---@param point Point
---@param msb BattleMenuContext
---@param _ctx any
---@return boolean
local function filter_no_unit(point, msb, _ctx)
    return not point_is_any_unit(point, msb.battle_map)
end

---@param point Point
---@param msb BattleMenuContext
---@param _ctx any
---@return boolean
local function filter_deployment_tile(point, msb, _ctx)
    return msb.battle_map:tile_has_label(point, msb.deployment_tiles_tag)
end

---@param point Point
---@param msb BattleMenuContext
---@param ctx BattleMainMenuContext
---@return boolean
local function filter_move_destination(point, msb, ctx)
    local valid_tiles = msb.tactics_engine:get_valid_tiles_for_unit(ctx.acting_unit.unit)
    return point_is_empty_or_acting_unit(point, msb.battle_map, ctx)
        and valid_tiles:get(point.x, point.y) ~= nil
        and valid_tiles:get(point.x, point.y) & 0x1 ~= 0
end

---@param point Point
---@param msb BattleMenuContext
---@param ctx BattleMainMenuContext
---@return boolean
local function filter_attack_destination(point, msb, ctx)
    local valid_tiles = msb.tactics_engine:get_valid_tiles_for_unit(ctx.acting_unit.unit)
    return point_is_enemy_unit(point, msb.battle_map)
        and valid_tiles:get(point.x, point.y) ~= nil
        and valid_tiles:get(point.x, point.y) & 0x4 ~= 0
end

---@param point Point
---@param msb BattleMenuContext
---@param ctx BattleMainMenuContext
---@return boolean
local function filter_interaction_destination(point, msb, ctx)
    local valid_tiles = msb.tactics_engine:get_valid_tiles_for_unit(ctx.acting_unit.unit)
    return get_single_unit_interaction(
        point, valid_tiles, ctx.acting_unit.unit, msb.battle_map
    ) ~= nil
end

---@param point Point
---@param msb BattleMenuContext
---@param ctx BattleMainMenuContext
---@return boolean
local function filter_attack_target(point, msb, ctx)
    return validate_tile_is_in_unit_attack_range(
        msb.battle_map,
        ctx.acting_unit.unit,
        ctx.acting_unit.unit.tile,
        point
    )
end

---@param point Point
---@param msb BattleMenuContext
---@param ctx BattleMainMenuContext
---@return boolean
local function filter_skill_target(point, msb, ctx)
    local def = msb.tactics_engine.skill_defs[ctx.selected_skill_id]
    if not def then return false end
    return def.targeting.is_target_valid(ctx.destination.point, point, msb.battle_map, ctx.acting_unit.unit.side)
end

local function make_menu_data(map_width, map_height)
    return {
        ["MENU_DEPLOYMENT"] = {
            initial_step = "SELECT_SWAP_UNIT",
            handlers = DEPLOYMENT_HANDLERS,
            steps = {
                ["SELECT_SWAP_UNIT"] = step_definition.of_node(
                        grid.grid("select_swap_unit", map_width, map_height)
                        :with_child(
                            filter_available_player,
                            button.builder("select_swap_unit")
                            :handle_action("select", "select_swap_unit")
                            :advance_to("SELECT_SWAP_TARGET")
                        )
                        :with_child( -- marking for non-actable units
                            filter_any_unit,
                            button.builder("non_available_unit")
                            :handle_action("menu", "mark_unit")
                        )
                        :with_child( -- marking for non-units
                            filter_no_unit,
                            button.builder("non_unit")
                            :handle_action("menu", "navigate_to_deployment_menu")
                        )
                        :with_tile_highlights(get_deployment_tiles)
                        :with_initial_point(function(services, _ctx)
                            ---@cast services BattleMenuContext
                            return services.tactics_engine.active_point
                        end)
                    )
                    :with_action("BUTTON_A", { command = "select", description = "Select Unit" })
                    :with_action("BUTTON_B", { command = "menu", description = "Menu" }),
                ["SELECT_SWAP_TARGET"] = step_definition.of_node(
                        grid.grid("select_swap_target", map_width, map_height)
                        :with_child(
                            filter_deployment_tile,
                            button.builder("swap_units")
                            :handle_action("select", "swap_units")
                            :advance_to("SELECT_SWAP_UNIT")
                        -- :as_final_step()
                        )
                        :with_child( -- marking for non-actable units
                            filter_any_unit,
                            button.builder("non_available_unit")
                            :handle_action("back", "mark_unit")
                        )
                        :with_tile_highlights(get_deployment_tiles)
                        :with_initial_point(function(services, _ctx)
                            ---@cast services BattleMenuContext
                            return services.tactics_engine.active_point
                        end)
                    )
                    :with_previous_step("SELECT_SWAP_UNIT")
                    :with_action("BUTTON_A", { command = "select", description = "Select Swap Target" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["DEPLOYMENT_MENU"] = step_definition.of_node(
                        list.column(
                            "deployment_menu",
                            function(_msb, _ctx)
                                local options = {}
                                table.insert(options, button.builder("start_battle")
                                    :with_text("Start Battle")
                                    :handle_action("select", "start_battle"))
                                table.insert(options, button.builder("edit_formation")
                                    :with_text("Edit Formation")
                                    :then_go_back())
                                return options
                            end
                        )
                    ):with_previous_step("SELECT_SWAP_UNIT")
                    :with_action("BUTTON_A", { command = "select", description = "Select" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
            }
        },
        ["MENU_PLAYER_TURN"] = {
            initial_step = "SELECT_UNIT",
            handlers = PLAYER_TURN_HANDLERS,
            steps = {
                ["SELECT_UNIT"] = step_definition.of_node(
                        grid.grid("select_acting_unit", map_width, map_height)
                        :with_child(
                            filter_available_player,
                            button.builder("available_player")
                            :handle_action("select", "select_acting_unit")
                            :handle_action("menu", "mark_unit")
                            :advance_to("SELECT_DESTINATION")
                        )
                        :with_child( -- marking for non-actable units
                            filter_any_unit,
                            button.builder("non_available_unit")
                            :handle_action("menu", "mark_unit")
                        )
                        :with_child( -- marking for non-units
                            filter_no_unit,
                            button.builder("non_unit")
                            :handle_action("menu", "navigate_to_turn_menu")
                        )
                        :with_common_child( -- unit cycling
                            button.builder("cycle_units")
                            :handle_action("cycle_left", "cycle_previous_unit")
                            :handle_action("cycle_right", "cycle_next_unit")
                        )
                        :with_tile_highlights(get_players_to_act_tiles)
                        :with_initial_point(function(services, _ctx)
                            ---@cast services BattleMenuContext
                            return services.tactics_engine.active_point
                        end)
                    )
                    :with_action("BUTTON_A", { command = "select", description = "Select Unit" })
                    :with_action("BUTTON_B", { command = "menu", description = "Menu / Mark Enemy" })
                    :with_action("SHOULDER_L", { command = "cycle_left", description = "Previous Unit" })
                    :with_action("SHOULDER_R", { command = "cycle_right", description = "Next Unit" }),
                ["SELECT_DESTINATION"] = step_definition.of_node(
                        grid.grid("select_destination", map_width, map_height)
                        :with_child(
                            filter_move_destination,
                            button.builder("move_unit")
                            :handle_action("select", "move_acting_unit")
                            :advance_to("SELECT_ACTION")
                        )
                        :with_child(
                            filter_attack_destination,
                            button.builder("attack_unit")
                            :handle_action("select", "move_and_store_attack_unit")
                            :advance_to("CONFIRM_ATTACK")
                        )
                        :with_child(
                            filter_interaction_destination,
                            button.builder("interaction_unit")
                            :handle_action("select", "move_and_store_interaction_unit")
                            :advance_to("CONFIRM_INTERACTION")
                        )
                        :with_tile_highlights(get_tile_highlights_in_move_and_attack_range)
                        :with_path_length(function(_msb, ctx)
                            ---@cast ctx BattleMainMenuContext
                            return ctx.acting_unit.unit.character.stats.movement
                        end)
                        :with_path_anchor(function(_msb, ctx)
                            ---@cast ctx BattleMainMenuContext
                            return ctx.acting_unit.point:copy()
                        end)
                        :with_initial_point(function(services, _ctx)
                            ---@cast services BattleMenuContext
                            return services.tactics_engine.active_point
                        end)
                        :with_on_change("trim_attack_path")
                    )
                    :with_previous_step("SELECT_UNIT")
                    :with_action("BUTTON_A", { command = "select", description = "Select Destination" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["SELECT_ACTION"] = step_definition.of_node(
                        list.column(
                            "select_action",
                            function(msb, ctx)
                                ---@cast msb BattleMenuContext
                                ---@cast ctx BattleMainMenuContext
                                local options = {}
                                -- if target in range
                                if any_target_in_range(msb.battle_map, ctx) then -- TODO: global state
                                    table.insert(options, button.builder("attack")
                                        :with_text("Attack")
                                        :advance_to("SELECT_TARGET"))
                                end

                                local nearby_interactions = msb.battle_map:get_nearby_interactions(ctx.destination.point)
                                for _, interaction in ipairs(nearby_interactions) do
                                    local id = "interaction_" .. interaction.script_id
                                    if interaction.target_tile then
                                        id = id .. "_" .. tostring(interaction.target_tile)
                                    end
                                    if interaction.target_unit then
                                        id = id .. "_" .. interaction.target_unit.id
                                    end
                                    table.insert(options, button.builder(id)
                                        :with_text(interaction.interaction_text)
                                        :with_value(interaction)
                                        :handle_action("select", "handle_interaction")
                                        :as_final_step())
                                end

                                local skill_loadout = ctx.acting_unit.unit.character.skill_loadout
                                if #skill_loadout > 0 then
                                    table.insert(options, button.builder("skills")
                                        :with_text("Skills")
                                        :advance_to("SELECT_SKILL"))
                                end

                                if not msb.tutorial_mode then
                                    table.insert(options, button.builder("wait")
                                        :with_text("Wait")
                                        :handle_action("select", "wait_acting_unit")
                                        :as_final_step())
                                end

                                table.insert(options, button.builder("cancel")
                                    :with_text("Cancel")
                                    :then_go_back_to("SELECT_UNIT"))
                                --- currently disabled as items aren't mechanically interesting yet
                                -- table.insert(options, {
                                --     text = "Items",
                                --     next_state = "SELECT_ITEM"
                                -- })

                                return options
                            end)
                    )
                    :with_previous_step("SELECT_DESTINATION")
                    :handle_action("back", "unmove_acting_unit")
                    :with_action("BUTTON_A", { command = "select", description = "Select" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["SELECT_TARGET"] = step_definition.of_node(
                        grid.grid("select_target", map_width, map_height)
                        :with_child(
                            filter_attack_target,
                            button.builder("attack_unit")
                            :handle_action("select", "attack_unit_at_tile")
                            :as_final_step()
                        )
                        -- :with_common_child( -- unit cycling
                        --     button.builder("cycle_units")
                        --         :handle_action("cycle_left", "cycle_previous_target")
                        --         :handle_action("cycle_right", "cycle_next_target")
                        -- )
                        :with_tile_highlights(function(msb, ctx)
                            ---@cast msb BattleMenuContext
                            ---@cast ctx BattleMainMenuContext
                            return msb.tactics_engine:tiles_with_distance_from_unit_attacks(ctx.acting_unit.unit,
                                ctx.destination.point)
                        end)
                        :with_path_length(function(_msb, ctx)
                            ---@cast ctx BattleMainMenuContext
                            return ctx.acting_unit.unit.character.stats.movement
                        end)
                        :with_path_anchor(function(_msb, ctx)
                            ---@cast ctx BattleMainMenuContext
                            return ctx.acting_unit.point:copy()
                        end)
                        :with_initial_point(function(services, _ctx)
                            ---@cast services BattleMenuContext
                            return services.tactics_engine.active_point
                        end)
                    )
                    :with_previous_step("SELECT_ACTION")
                    :with_action("BUTTON_A", { command = "select", description = "Select Target" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                -- :with_action("SHOULDER_L", { command = "cycle_left", description = "Previous Target" })
                -- :with_action("SHOULDER_R", { command = "cycle_right", description = "Next Target" }),
                ["SELECT_SKILL"] = step_definition.of_node(
                        list.column(
                            "select_skill",
                            function(msb, ctx)
                                ---@cast msb BattleMenuContext
                                ---@cast ctx BattleMainMenuContext
                                local options = {}
                                local unit = ctx.acting_unit.unit
                                local skill_defs = msb.tactics_engine.skill_defs
                                local destination = ctx.destination.point

                                for _, skill_id in ipairs(unit.character.skill_loadout) do
                                    local def = skill_defs[skill_id]
                                    if def then
                                        local state = unit.skill_states[skill_id]
                                        local reason = nil

                                        local uses = state and state.uses_remaining
                                        if uses ~= nil and uses == 0 then
                                            reason = "0/" .. def.uses_per_battle
                                        elseif state and state.cooldown_remaining > 0 then
                                            reason = "CD:" .. state.cooldown_remaining
                                        else
                                            for _, effect in ipairs(def.effects) do
                                                if effect.type == "hp_cost" and effect.amount >= unit.hp_current then
                                                    reason = "HP"
                                                    break
                                                end
                                            end
                                        end
                                        if reason == nil then
                                            local tiles = def.targeting.get_selection_tiles(destination, msb.battle_map, unit.side)
                                            if #tiles == 0 then
                                                reason = "no targets"
                                            end
                                        end

                                        if reason then
                                            table.insert(options, button.builder(skill_id)
                                                :with_text(def.name .. "  " .. reason))
                                        else
                                            table.insert(options, button.builder(skill_id)
                                                :with_text(def.name)
                                                :with_value(skill_id)
                                                :handle_action("select", "store_selected_skill")
                                                :advance_to("SELECT_SKILL_TARGET"))
                                        end
                                    end
                                end

                                return options
                            end
                        )
                    )
                    :with_previous_step("SELECT_ACTION")
                    :with_action("BUTTON_A", { command = "select", description = "Select" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["SELECT_SKILL_TARGET"] = step_definition.of_node(
                        grid.grid("select_skill_target", map_width, map_height)
                        :with_child(
                            filter_skill_target,
                            button.builder("use_skill")
                            :handle_action("select", "use_skill_at_tile")
                            :as_final_step()
                        )
                        :with_tile_highlights(function(msb, ctx)
                            ---@cast msb BattleMenuContext
                            ---@cast ctx BattleMainMenuContext
                            local def = msb.tactics_engine.skill_defs[ctx.selected_skill_id]
                            if not def then
                                return msb.battle_map:get_tiles_userdata_by("u8", function() return 0 end)
                            end
                            local tiles = def.targeting.get_selection_tiles(ctx.destination.point, msb.battle_map, ctx.acting_unit.unit.side)
                            local tile_set = {}
                            for _, t in ipairs(tiles) do
                                tile_set[t.x .. "," .. t.y] = true
                            end
                            return msb.battle_map:get_tiles_userdata_by("u8", function(p)
                                return tile_set[p.x .. "," .. p.y] and HIGHLIGHT.IS_VALID or 0
                            end)
                        end)
                        :with_initial_point(function(services, _ctx)
                            ---@cast services BattleMenuContext
                            return services.tactics_engine.active_point
                        end)
                    )
                    :with_previous_step("SELECT_SKILL")
                    :with_action("BUTTON_A", { command = "select", description = "Select Target" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["CONFIRM_ATTACK"] = step_definition.of_node(
                        list.column(
                            "confirm_attack",
                            function(_msb, ctx)
                                ---@cast ctx BattleMainMenuContext
                                local options = {}
                                table.insert(options, button.builder("attack")
                                    :with_text("Attack")
                                    :handle_action("select", "attack_unit")
                                    :as_final_step())
                                table.insert(options, button.builder("cancel")
                                    :with_text("Cancel")
                                    :then_go_back())
                                return options
                            end)
                    )
                    :with_previous_step("SELECT_DESTINATION")
                    :handle_action("back", "unmove_acting_unit")
                    :with_action("BUTTON_A", { command = "select", description = "Select" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["CONFIRM_INTERACTION"] = step_definition.of_node(
                        list.column(
                            "confirm_interaction",
                            function(_msb, ctx)
                                ---@cast ctx BattleMainMenuContext
                                local options = {}
                                table.insert(options, button.builder("do_interaction")
                                    :with_text(ctx.stored_interaction.interaction_text)
                                    :with_value(ctx.stored_interaction)
                                    :handle_action("select", "handle_interaction")
                                    :as_final_step())
                                table.insert(options, button.builder("cancel_interaction")
                                    :with_text("Cancel")
                                    :then_go_back())
                                return options
                            end)
                    )
                    :with_previous_step("SELECT_DESTINATION")
                    :handle_action("back", "unmove_acting_unit")
                    :with_action("BUTTON_A", { command = "select", description = "Select" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
                ["TURN_MENU"] = step_definition.of_node(
                        list.column(
                            "turn_menu",
                            function(msb, _ctx)
                                ---@cast msb BattleMenuContext
                                local options = {}
                                if not msb.tutorial_mode then
                                    table.insert(options, button.builder("end_turn")
                                        :with_text("End Turn")
                                        :handle_action("select", "end_turn"))
                                end
                                table.insert(options, button.builder("mark_all_units")
                                    :with_text("Mark All Enemies")
                                    :handle_action("select", "mark_all_units")
                                    :then_go_back())
                                table.insert(options, button.builder("unmark_all_units")
                                    :with_text("Unmark All Enemies")
                                    :handle_action("select", "unmark_all_units")
                                    :then_go_back())
                                table.insert(options, button.builder("turn_menu_back")
                                    :with_text("Back")
                                    :then_go_back())
                                return options
                            end
                        )
                    )
                    :with_previous_step("SELECT_UNIT")
                    :with_action("BUTTON_A", { command = "select", description = "Select" })
                    :with_action("BUTTON_B", { command = "back", description = "Back" }),
            }
        }
    }
end

local battle_menu_manager = {
    BattleMenuManager = BattleMenuManager
}

--- Create a new BattleMenuManager with the battle-specific menu definitions.
---@param ctx BattleMenuContext
---@param bus EventBus
---@return BattleMenuManager
function battle_menu_manager.new(ctx, bus)
    return menu_manager.new(
        make_menu_data(ctx.battle_map.width, ctx.battle_map.height),
        ctx,
        bus
    ) --[[@as BattleMenuManager]]
end

return battle_menu_manager
