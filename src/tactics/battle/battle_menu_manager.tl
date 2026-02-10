---@brief
--- Manages the menu system used during a battle.
--- Defines the structure and flow of in-battle menus, such as the
--- unit action menu and deployment screen.

local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local Point = require("src.tactics.util.point").Point
local bm = require("src.tactics.battle.battle_map")
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local event_bus = require("src.tactics.systems.event_bus")
local BattleMenuContext = require("src.tactics.battle.battle_menu_context").BattleMenuContext
local array_2d = require("src.tactics.util.array_2d")
local menu_types = require("src.tactics.menu.types")
local menu_context = require("src.tactics.menu.menu_context")
local GameContext = menu_context.GameContext
local BattleMainMenuContext = menu_context.BattleMainMenuContext
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local nested_cursor = require("src.tactics.menu.cursor.nested_cursor")
local grid = require("src.tactics.menu.cursor.nested.grid")
local button = require("src.tactics.menu.cursor.button")
local ButtonDefinition = button.ButtonDefinition
local ButtonCursor = button.ButtonCursor
local selection = require("src.tactics.menu.cursor.selection")
local SelectionDefinition = selection.SelectionMenuDefinition
local SelectionCursor = selection.SelectionMenuNode

local record BattleMenuManager
    is menu_manager.MenuManager
end


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

local function get_deployment_tiles(msb: BattleMenuContext, _ctx: BattleMainMenuContext): array_2d.Array2D<grid.MenuTileHighlight>
    return msb.battle_map:get_tiles_array_by_label(msb.deployment_tiles_tag)
        :map(function(is_deployment: boolean): grid.MenuTileHighlight
            return {
                valid_selection = is_deployment,
            }
        end)
end

local function get_players_to_act_tiles(msb: BattleMenuContext, _ctx: BattleMainMenuContext): array_2d.Array2D<grid.MenuTileHighlight>
    --todo
    return msb.battle_map:get_tiles_array_by_label(msb.deployment_tiles_tag)
        :map(function(is_deployment: boolean): grid.MenuTileHighlight
            return {
                valid_selection = is_deployment,
            }
        end)
end

local function get_tile_highlights_in_move_and_attack_range(msb: BattleMenuContext, ctx: BattleMainMenuContext): array_2d.Array2D<grid.MenuTileHighlight>
    return msb.tactics_engine:tiles_in_movement_and_attack_range(ctx.acting_unit.unit)
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
    ["MENU_DEPLOYMENT"] = {
        initial_step = "SELECT_SWAP_UNIT",
        steps = {
            ["SELECT_SWAP_UNIT"] = step_definition.of_node(
                grid.grid()
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattlePreparationsContext): boolean
                            return point_is_available_player(point, msb.battle_map)
                        end,
                        button.builder()
                            :handle_select(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattlePreparationsContext)
                                local point = self.value as Point
                                ctx.unit = game_ctx.battle_map:get_at_tile(point)
                                game_ctx.tactics_engine:handle_swap_unit(
                                    ctx.unit,
                                    ctx.swap_target
                                )
                            end)
                            :advance_to("SELECT_SWAP_TARGET")
                    )
                    :with_tile_highlights(get_deployment_tiles)
                )
                :with_previous_step("DEPLOYMENT_MENU"),
            ["SELECT_SWAP_TARGET"] = step_definition.of_node(
                grid.grid()
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattlePreparationsContext): boolean
                            return msb.battle_map:tile_has_label(point, msb.deployment_tiles_tag)
                        end,
                        button.builder()
                            :handle_select(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattlePreparationsContext)
                                local point = self.value as Point
                                ctx.swap_target = point:copy()
                                game_ctx.tactics_engine:handle_swap_unit(
                                    ctx.unit,
                                    ctx.swap_target
                                )
                            end)
                            :advance_to("SELECT_SWAP_UNIT")
                    )
                    :with_tile_highlights(get_deployment_tiles)
                )
                :with_previous_step("SELECT_SWAP_UNIT"),
            ["DEPLOYMENT_MENU"] = step_definition.of_node(
                nested_cursor.column(
                    function(_msb: BattleMenuContext, _ctx: BattleMainMenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}

                        pt.add(options, button.builder()
                            :with_text("Start Battle")
                            :handle_select(function(_self: ButtonCursor, game_ctx: BattleMenuContext, _menu_ctx: BattleMainMenuContext)
                                game_ctx.handle_start_battle()
                            end))
                        pt.add(options, button.builder()
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
                grid.grid()
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                            return point_is_available_player(point, msb.battle_map)
                        end,
                        button.builder()
                            :handle_select(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattleMainMenuContext)
                                local point = self.value as Point
                                ctx.acting_unit = {
                                    unit = game_ctx.battle_map:get_at_tile(point),
                                    point = point:copy()
                                }
                            end)
                            :handle_back(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattleMainMenuContext)
                                local point = self.value as Point
                                game_ctx.tactics_engine:handle_mark_unit(point)
                            end)
                            :advance_to("SELECT_DESTINATION")
                    )
                    :with_child( -- marking for non-actable units
                        function(point: Point, msb: BattleMenuContext, ctx: BattlePreparationsContext): boolean
                            return point_is_any_unit(point, msb.battle_map)
                        end,
                        button.builder()
                            :handle_back(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattleMainMenuContext)
                                local point = self.value as Point
                                game_ctx.tactics_engine:handle_mark_unit(point)
                            end)
                            :advance_to("SELECT_DESTINATION")
                    )
                    :with_tile_highlights(get_players_to_act_tiles)
                ),
             ["SELECT_DESTINATION"] = step_definition.of_node(
                grid.grid()
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                            return point_is_empty_or_acting_unit(point, msb.battle_map, ctx)
                                                    and ctx.acting_unit.unit.valid_tiles:get(point.x, point.y) ~= nil
                                                    and ctx.acting_unit.unit.valid_tiles:get(point.x, point.y) & 0x1 ~= 0
                        end,
                        button.builder()
                            :handle_select(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattleMainMenuContext)
                                local point = self.value as Point
                                ctx.destination = { point = point:copy(), path = s.path }
                                game_ctx.tactics_engine:handle_move_unit(
                                    ctx.acting_unit.unit,
                                    ctx.destination.point,
                                    ctx.destination.path
                                )
                            end)
                            :advance_to("SELECT_ACTION")
                    )
                    :with_tile_highlights(get_tile_highlights_in_move_and_attack_range)
                    :with_path_length(function(_: BattleMenuContext, ctx: BattleMainMenuContext): integer
                        return ctx.acting_unit.unit.character.stats.movement
                    end)
                    :with_path_anchor(function(_: BattleMenuContext, ctx: BattleMainMenuContext): Point
                        return ctx.acting_unit.point:copy()
                    end)
                )
                :with_previous_step("SELECT_UNIT"),
            ["SELECT_ACTION"] = step_definition.of_node(
                nested_cursor.column(
                    function(msb: BattleMenuContext, ctx: BattleMainMenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}
                        -- if target in range
                        if any_target_in_range(msb.battle_map, ctx) then -- TODO: global state
                            pt.add(options, button.builder()
                                :with_text("Attack")
                                :advance_to("SELECT_TARGET"))
                        end

                        local nearby_interactions = msb.battle_map:get_nearby_interactions(ctx.destination.point)
                        for _, interaction in ipairs(nearby_interactions) do
                            pt.add(options, button.builder()
                                :with_text(interaction.interaction_text)
                                :advance_to("SELECT_TARGET")
                                :handle_select(function(_self: ButtonCursor, game_ctx: BattleMenuContext, _menu_ctx: BattleMainMenuContext)
                                    game_ctx.handle_start_battle()
                                end))
                            pt.add(options, {
                                text = interaction.interaction_text,
                                select_handler = function(_self: grid_cursor.GridMenuNode, game_ctx: BattleMenuContext, menu_ctx: BattleMainMenuContext)
                                    game_ctx.tactics_engine:handle_interaction(
                                        interaction.script_id,
                                        menu_ctx.acting_unit.unit,
                                        interaction.target_unit,
                                        interaction.target_tile
                                    )
                                end,
                                set_selected_context = function(_: BattleMenuContext, mc: BattleMainMenuContext)
                                    mc.selected_script = {
                                        script_id = interaction.script_id,
                                        target_unit = interaction.target_unit,
                                        target_tile = interaction.target_tile,
                                    }
                                end
                            })
                        end

                        pt.add(options, button.builder()
                            :with_text("Wait")
                            :handle_select(function(_self: ButtonCursor, game_ctx: BattleMenuContext, menu_ctx: BattleMainMenuContext)
                                game_ctx.tactics_engine:finish_unit_action(
                                    menu_ctx.acting_unit.unit
                                )
                            end))

                        --- currently disabled as items aren't mechanically interesting yet
                        -- pt.add(options, {
                        --     text = "Items",
                        --     next_state = "SELECT_ITEM"
                        -- })
                    
                        return options
                    end)
                )
                :with_previous_step("SELECT_DESTINATION")
                :handle_back(function(game_ctx: BattleMenuContext, menu_ctx: BattleMainMenuContext)
                    game_ctx.tactics_engine:jump_unit_to_point(
                        menu_ctx.acting_unit.unit,
                        menu_ctx.acting_unit.point
                    )
                end),
             ["SELECT_TARGET"] = step_definition.of_node(
                grid.grid()
                    :with_child(
                        function(point: Point, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                            validate_tile_is_in_unit_attack_range(msb.battle_map, ctx.acting_unit.unit, ctx.destination.point, point)
                        end,
                        button.builder()
                            :handle_select(function(self: ButtonCursor, game_ctx: BattleMenuContext, ctx: BattleMainMenuContext)
                                local point = self.value as Point
                                ctx.target_unit = { unit = game_ctx.battle_map:get_at_tile(point)}
                                game_ctx.tactics_engine:handle_attack_unit(
                                    ctx.acting_unit.unit,
                                    ctx.target_unit.unit
                                )
                            end)
                            :advance_to("SELECT_ACTION")
                    )
                    :with_tile_highlights(function (msb: BattleMenuContext, ctx: BattleMainMenuContext): array_2d.Array2D<grid.MenuTileHighlight>
                        return msb.tactics_engine:tiles_with_distance_from_unit_attacks(ctx.acting_unit.unit, ctx.destination.point)
                    end)
                    :with_path_length(function(_: BattleMenuContext, ctx: BattleMainMenuContext): integer
                        return ctx.acting_unit.unit.character.stats.movement
                    end)
                    :with_path_anchor(function(_: BattleMenuContext, ctx: BattleMainMenuContext): Point
                        return ctx.acting_unit.point:copy()
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
        ctx,
        bus
    ) as BattleMenuManager
end

return battle_menu_manager
