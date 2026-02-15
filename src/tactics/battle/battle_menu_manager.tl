---@brief
--- Manages the menu system used during a battle.
--- Defines the structure and flow of in-battle menus, such as the
--- unit action menu and deployment screen.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local Point = require("src.tactics.util.point").Point
local bm = require("src.tactics.battle.battle_map")
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local event_bus = require("src.tactics.systems.event_bus")
local BattleMenuContext = require("src.tactics.battle.battle_menu_context").BattleMenuContext
local battle_map_types = require("src.tactics.battle.battle_map.types")
local InteractionHook = battle_map_types.InteractionHook
local menu_types = require("src.tactics.menu.types")
local menu_context = require("src.tactics.menu.menu_context")
local BattleMainMenuContext = menu_context.BattleMainMenuContext
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local list = require("src.tactics.menu.cursor.nested.list")
local grid = require("src.tactics.menu.cursor.nested.grid")
local button = require("src.tactics.menu.cursor.button")

local record BattleMenuManager
    is menu_manager.MenuManager
end

local MAP_WIDTH = STATIC_CONFIG.MAP_WIDTH
local MAP_HEIGHT = STATIC_CONFIG.MAP_HEIGHT

local function point_is_empty_or_acting_unit(
    point: Point,
    map: bm.BattleMap,
    ctx: BattleMainMenuContext
): boolean
    local destination_unit = map:get_at_tile(point)
    if destination_unit == nil then
        return true
    end
    local acting_unit = ctx.acting_unit.unit
    return destination_unit.id == acting_unit.id
end

local function point_is_available_player(
    point: Point,
    map: bm.BattleMap
): boolean
    local unit = map:get_at_tile(point)

    if unit == nil then return false end
    if not unit:is_player() then return false end
    if unit.has_acted then return false end

    return true
end

local function point_is_any_unit(
    point: Point,
    map: bm.BattleMap
): boolean
    local unit = map:get_at_tile(point)

    return unit ~= nil
end

local function any_target_in_range(
    map: bm.BattleMap,
    ctx: BattleMainMenuContext
): boolean
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    
    local units_in_range = map:get_targets_in_range(unit.id, destination)
    return #units_in_range > 0
end

local function validate_tile_is_in_unit_attack_range(
    map: bm.BattleMap,
    unit: BattleUnit,
    unit_position: Point,
    target_point: Point 
): boolean
    local targeting = unit.character:get_weapon_targeting()
    local target_unit = map:get_at_tile(target_point)
    if target_unit == nil then return false end

    if target_unit.side == unit.side then return false end

    return targeting.is_target_valid(unit_position, target_point, map)
end

local record BattlePreparationsContext
    is menu_context.MenuContext
    unit: BattleUnit
    swap_target: Point
end

local function get_deployment_tiles(msb: BattleMenuContext, _ctx: BattleMainMenuContext): Userdata
    log.debug("getting deployment tiles")
    return msb.battle_map:get_tiles_userdata_by(
        "u8",
        function(p: Point): integer
            return msb.battle_map:tile_has_label(p, msb.deployment_tiles_tag)
                and HIGHLIGHT.IS_VALID
                or 0
        end)
end

local function get_players_to_act_tiles(msb: BattleMenuContext, _ctx: BattleMainMenuContext): Userdata
    return msb.battle_map:get_tiles_userdata_by(
        "u8",
        function(p: Point): integer
            local unit = msb.battle_map:get_at_tile(p)
            return (unit and unit:is_player() and not unit.has_acted)
                and HIGHLIGHT.IS_VALID
                or 0
        end)
end

local function get_tile_highlights_in_move_and_attack_range(msb: BattleMenuContext, ctx: BattleMainMenuContext): Userdata
    return msb.tactics_engine:tiles_in_movement_and_attack_range(ctx.acting_unit.unit)
end

local HANDLERS: { menu_types.MenuHandlerId: menu_manager.MenuHandler } = {}

HANDLERS["select_swap_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattlePreparationsContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    session_context.unit = services.battle_map:get_at_tile(value.point)
    return nil
end

HANDLERS["swap_units"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattlePreparationsContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.tactics_engine:handle_swap_unit(
        session_context.unit,
        value.point
    )

    return nil
end

HANDLERS["start_battle"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    _session_context: BattlePreparationsContext,
    _value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.handle_start_battle()

    return nil
end

HANDLERS["select_acting_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattleMainMenuContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    local unit = services.battle_map:get_at_tile(value.point)
    session_context.acting_unit = {
        unit = unit,
        point = unit.tile:copy(),
    }

    return nil
end

HANDLERS["mark_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    _session_context: BattleMainMenuContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.tactics_engine:handle_mark_unit(value.point)

    return nil
end

HANDLERS["wait_acting_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattleMainMenuContext,
    _value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.tactics_engine:finish_unit_action(session_context.acting_unit.unit)

    return nil
end

HANDLERS["move_acting_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattleMainMenuContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    session_context.destination = {
        point = value.point,
        path = value.path,
    }
    services.tactics_engine:handle_move_unit(
        session_context.acting_unit.unit,
        session_context.destination.point,
        session_context.destination.path
    )

    return nil
end

HANDLERS["unmove_acting_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattleMainMenuContext,
    _value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.tactics_engine:jump_unit_to_point(
        session_context.acting_unit.unit,
        session_context.acting_unit.point
    )

    return nil
end

HANDLERS["attack_unit"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattleMainMenuContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
    session_context.target_unit = { unit = services.battle_map:get_at_tile(value.point)}
    services.tactics_engine:handle_attack_unit(
        session_context.acting_unit.unit,
        session_context.target_unit.unit
    )

    return nil
end

HANDLERS["handle_interaction"] = function(
    services: BattleMenuContext,
    _menu_data: {string: any},
    session_context: BattleMainMenuContext,
    interaction: InteractionHook
): menu_manager.menu_handler.MenuHandlerPostHandling
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

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
    ["MENU_DEPLOYMENT"] = {
        initial_step = "SELECT_SWAP_UNIT",
        steps = {
            ["SELECT_SWAP_UNIT"] = step_definition.of_node(
                grid.grid("select_swap_unit", MAP_WIDTH, MAP_HEIGHT)
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, _ctx: BattlePreparationsContext): boolean
                            return point_is_available_player(point, msb.battle_map)
                        end,
                        button.builder("select_swap_unit")
                            :handle_select("select_swap_unit")
                            :advance_to("SELECT_SWAP_TARGET")
                    )
                    :with_tile_highlights(get_deployment_tiles)
                    :with_initial_point(function(services: BattleMenuContext, _ctx: BattleMainMenuContext): Point
                        return services.tactics_engine.active_point
                    end)
                )
                :with_previous_step("DEPLOYMENT_MENU"),
            ["SELECT_SWAP_TARGET"] = step_definition.of_node(
                grid.grid("select_swap_target", MAP_WIDTH, MAP_HEIGHT)
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, _ctx: BattlePreparationsContext): boolean
                            return msb.battle_map:tile_has_label(point, msb.deployment_tiles_tag)
                        end,
                        button.builder("swap_units")
                            :handle_select("swap_units")
                            :advance_to("SELECT_SWAP_UNIT")
                    )
                    :with_tile_highlights(get_deployment_tiles)
                    :with_initial_point(function(services: BattleMenuContext, _ctx: BattleMainMenuContext): Point
                        return services.tactics_engine.active_point
                    end)
                )
                :with_previous_step("SELECT_SWAP_UNIT"),
            ["DEPLOYMENT_MENU"] = step_definition.of_node(
                list.column(
                    "deployment_menu",
                    function(_msb: BattleMenuContext, _ctx: BattleMainMenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}

                        pt.add(options, button.builder("start_battle")
                            :with_text("Start Battle")
                            :handle_select("start_battle"))
                        pt.add(options, button.builder("edit_formation")
                            :with_text("Edit Formation")
                            :advance_to("SELECT_SWAP_UNIT"))
                    
                        return options
                    end
                )
            ):with_previous_step("SELECT_SWAP_UNIT"),
        }
    },
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = step_definition.of_node(
                grid.grid("select_acting_unit", MAP_WIDTH, MAP_HEIGHT)
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, _ctx: BattleMainMenuContext): boolean
                            return point_is_available_player(point, msb.battle_map)
                        end,
                        button.builder("available_player")
                            :handle_select("select_acting_unit")
                            :handle_back("mark_unit")
                            :advance_to("SELECT_DESTINATION")
                    )
                    :with_child( -- marking for non-actable units
                        function(point: Point, msb: BattleMenuContext, _ctx: BattlePreparationsContext): boolean
                            return point_is_any_unit(point, msb.battle_map)
                        end,
                        button.builder("non_available_unit")
                            :handle_back("mark_unit")
                    )
                    :with_tile_highlights(get_players_to_act_tiles)
                    :with_initial_point(function(services: BattleMenuContext, _ctx: BattleMainMenuContext): Point
                        return services.tactics_engine.active_point
                    end)
                ),
             ["SELECT_DESTINATION"] = step_definition.of_node(
                grid.grid("select_destination", MAP_WIDTH, MAP_HEIGHT)
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                            return point_is_empty_or_acting_unit(point, msb.battle_map, ctx)
                                                    and ctx.acting_unit.unit.valid_tiles:get(point.x, point.y) ~= nil
                                                    and ctx.acting_unit.unit.valid_tiles:get(point.x, point.y) & 0x1 ~= 0
                        end,
                        button.builder("move_unit")
                            :handle_select("move_acting_unit")
                            :advance_to("SELECT_ACTION")
                    )
                    :with_tile_highlights(get_tile_highlights_in_move_and_attack_range)
                    :with_path_length(function(_: BattleMenuContext, ctx: BattleMainMenuContext): integer
                        return ctx.acting_unit.unit.character.stats.movement
                    end)
                    :with_path_anchor(function(_: BattleMenuContext, ctx: BattleMainMenuContext): Point
                        return ctx.acting_unit.point:copy()
                    end)
                    :with_initial_point(function(services: BattleMenuContext, _ctx: BattleMainMenuContext): Point
                        return services.tactics_engine.active_point
                    end)
                )
                :with_previous_step("SELECT_UNIT"),
            ["SELECT_ACTION"] = step_definition.of_node(
                list.column(
                    "select_action",
                    function(msb: BattleMenuContext, ctx: BattleMainMenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}
                        -- if target in range
                        if any_target_in_range(msb.battle_map, ctx) then -- TODO: global state
                            pt.add(options, button.builder("attack")
                                :with_text("Attack")
                                :advance_to("SELECT_TARGET"))
                        end

                        local nearby_interactions = msb.battle_map:get_nearby_interactions(ctx.destination.point)
                        for _, interaction in ipairs(nearby_interactions) do
                            local id = "interaction_"..interaction.script_id
                            if interaction.target_tile then
                                id = id.."_"..tostring(interaction.target_tile)
                            end
                            if interaction.target_unit then
                                id = id.."_"..interaction.target_unit.id
                            end
                            pt.add(options, button.builder(id)
                                :with_text(interaction.interaction_text)
                                :with_value(interaction)
                                :handle_select("handle_interaction"))
                        end

                        pt.add(options, button.builder("wait")
                            :with_text("Wait")
                            :handle_select("wait_acting_unit"))

                        --- currently disabled as items aren't mechanically interesting yet
                        -- pt.add(options, {
                        --     text = "Items",
                        --     next_state = "SELECT_ITEM"
                        -- })
                    
                        return options
                    end)
                )
                :with_previous_step("SELECT_DESTINATION")
                :handle_back("unmove_acting_unit"),
             ["SELECT_TARGET"] = step_definition.of_node(
                grid.grid("select_target", MAP_WIDTH, MAP_HEIGHT)
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                            return validate_tile_is_in_unit_attack_range(
                                msb.battle_map,
                                ctx.acting_unit.unit,
                                ctx.acting_unit.unit.tile,
                                point
                            )
                        end,
                        button.builder("attack_unit")
                            :handle_select("attack_unit")
                            :advance_to("SELECT_ACTION")
                    )
                    :with_tile_highlights(function (msb: BattleMenuContext, ctx: BattleMainMenuContext): Userdata
                        return msb.tactics_engine:tiles_with_distance_from_unit_attacks(ctx.acting_unit.unit, ctx.destination.point)
                    end)
                    :with_path_length(function(_: BattleMenuContext, ctx: BattleMainMenuContext): integer
                        return ctx.acting_unit.unit.character.stats.movement
                    end)
                    :with_path_anchor(function(_: BattleMenuContext, ctx: BattleMainMenuContext): Point
                        return ctx.acting_unit.point:copy()
                    end)
                    :with_initial_point(function(services: BattleMenuContext, _ctx: BattleMainMenuContext): Point
                        return services.tactics_engine.active_point
                    end)
                )
                :with_previous_step("SELECT_ACTION"),
            -- ["SELECT_ITEM"] = list_cursor.definition({
            --     previous_state = "SELECT_ACTION",
            --     set_selected_context = function(s: list_cursor.ListMenuNode<string>, _msb: BattleMenuContext, ctx: BattleMainMenuContext)
            --         ctx.selected_item = {
            --             index = s.i,
            --             item = ctx.acting_unit.unit.character.inventory:get_items()[s.i]
            --         }
            --     end,
            --     get_options = function(_msb: BattleMenuContext, ctx: BattleMainMenuContext): {list_cursor.ListMenuOption<string>}
            --             local character = ctx.acting_unit.unit
            --             local items = character.character.inventory:get_items()

            --             local options = {}
            --             for _,item in ipairs(items) do
            --                 pt.add(options, {
            --                     text = item:get_name(),
            --                     next_state = "SELECT_ITEM_ACTION"
            --                 })
            --             end
            --             return options
            --     end
            -- }),
            -- ["SELECT_ITEM_ACTION"] = list_cursor.definition({
            --     previous_state = "SELECT_ITEM",
            --     get_options = function(_msb: BattleMenuContext, ctx: BattleMainMenuContext): {list_cursor.ListMenuOption<string>}
            --             local character = ctx.acting_unit.unit
            --             local inventory = character.character.inventory
            --             local items = inventory:get_items()
            --             local item = ctx.selected_item.item
            --             local index = ctx.selected_item.index

            --             if inventory:get_items()[index] == nil then
            --                 return {}
            --             end
                        
            --             local options = {}

            --             -- TODO: consumables
            --             if item:get_equip_slot() ~= "NONE" then
            --                 if inventory:is_equipped(index) then
            --                     pt.add(options, {
            --                         text = "Unequip",
            --                         select_handler = "INVENTORY_UNEQUIP_ITEM",
            --                         next_state = "SELECT_ITEM_ACTION",
            --                     })
            --                 else
            --                     pt.add(options, {
            --                         text = "Equip",
            --                         select_handler = "INVENTORY_EQUIP_ITEM",
            --                         next_state = "SELECT_ITEM_ACTION",
            --                     })
            --                 end
            --             end

            --             if #items > 0 then
            --                 pt.add(options, {
            --                     text = "Move",
            --                 })
            --             end
            --             pt.add(options, {
            --                 text = "Discard",
            --                 select_handler = "INVENTORY_DISCARD_ITEM",
            --                 next_state = "SELECT_ITEM",
            --             })
                        
            --             return options
            --     end
            -- }),
        }
    }
}

local battle_menu_manager = {
    BattleMenuManager = BattleMenuManager
}

function battle_menu_manager.new(
    ctx: BattleMenuContext,
    bus: event_bus.EventBus
): BattleMenuManager
    return menu_manager.new(
        MENU_DATA,
        HANDLERS,
        ctx,
        bus
    ) as BattleMenuManager
end

return battle_menu_manager
