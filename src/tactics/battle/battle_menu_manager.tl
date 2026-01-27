local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
local Point = require("src/tactics/util/point").Point
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local menu_manager = require("src/tactics/menu/menu_manager")
local event_bus = require("src/tactics/systems/event_bus")
local BattleMenuContext = require("src/tactics/battle/battle_menu_context").BattleMenuContext
local array_2d = require("src/tactics/util/array_2d")
local grid_cursor = require("src/tactics/menu/cursor/grid_cursor")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local menu_types = require("src/tactics/menu/types")
local menu_context = require("src/tactics/menu/menu_context")
local MenuContext = menu_context.MenuContext
local BattleMainMenuContext = menu_context.BattleMainMenuContext

local record BattleMenuManager
    is menu_manager.MenuManager<BattleMenuContext>
end


local function grid_selection_is_empty_or_acting_unit(
    map: BattleMap,
    grid_selection: grid_cursor.GridMenuCursor<BattleMenuContext>,
    ctx: BattleMainMenuContext
): boolean
    local destination_unit = map:get_at_tile(grid_selection.point)
    if destination_unit == nil then
        return true
    end
    local acting_unit = ctx.acting_unit.unit
    return destination_unit.id == acting_unit.id
end

local function grid_selection_is_available_player(
    map: BattleMap,
    grid_selection: grid_cursor.GridMenuCursor<BattleMenuContext>
): boolean
    local unit = map:get_at_tile(grid_selection.point)

    if unit == nil then return false end
    if not unit:is_player() then return false end
    if unit.has_acted then return false end

    return true
end

local function any_target_in_range(
    map: BattleMap,
    ctx: BattleMainMenuContext
): boolean
    local unit = ctx.acting_unit.unit
    local destination = ctx.destination.point
    
    local units_in_range = map:get_targets_in_range(unit.id, destination)
    return #units_in_range > 0
end

local function validate_tile_is_in_unit_attack_range(
    map: BattleMap,
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

-- kind
-- selected_data_mapper -- returns (success bool, data) to store
-- select_transition
local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition<BattleMenuContext> } = {
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = grid_cursor.definition({
                set_selected_context = function(s: grid_cursor.GridMenuCursor<BattleMenuContext>, msb: BattleMenuContext, ctx: BattleMainMenuContext)
                    ctx.acting_unit = {
                        unit = msb.battle_map:get_at_tile(s.point),
                        point = s.point:copy()
                    }
                end,
                validator = function (s: grid_cursor.GridMenuCursor<BattleMenuContext>, msb: BattleMenuContext, _ctx: BattleMainMenuContext): boolean
                    return grid_selection_is_available_player(msb.battle_map, s) end,
                next_state = "SELECT_DESTINATION",
                back_command = "MARK_UNIT_RANGE",
            }),
            ["SELECT_DESTINATION"] = grid_cursor.definition({
                send_command = "MOVE_UNIT",
                set_selected_context = function(s: grid_cursor.GridMenuCursor<BattleMenuContext>, _msb: BattleMenuContext, ctx: BattleMainMenuContext)
                    ctx.destination = { point = s.point:copy(), path = s.path }
                end,
                validator = function (s: grid_cursor.GridMenuCursor<BattleMenuContext>, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                     return grid_selection_is_empty_or_acting_unit(msb.battle_map, s, ctx)
                        and s.legal_tiles:get_point(s.point) ~= nil
                        and s.legal_tiles:get_point(s.point).valid_selection
                end,
                next_state = "SELECT_ACTION",
                previous_state = "SELECT_UNIT",
                get_legal_tiles = function (msb: BattleMenuContext, ctx: BattleMainMenuContext): array_2d.Array2D<grid_cursor.MenuTileHighlight>
                    return msb.tactics_engine:tiles_in_movement_and_attack_range(ctx)
                end,
                get_max_path_length = function(_: BattleMenuContext, ctx: BattleMainMenuContext): integer
                    return ctx.acting_unit.unit.character.stats.movement
                end,
                get_path_anchor = function(_: BattleMenuContext, ctx: BattleMainMenuContext): Point
                    return ctx.acting_unit.point:copy()
                end
            }),
            ["SELECT_ACTION"] = list_cursor.definition({
                previous_state = "SELECT_DESTINATION",
                back_command = "JUMP_UNIT",
                get_options = function(msb: BattleMenuContext, ctx: BattleMainMenuContext): {list_cursor.ListMenuOption}
                    local options: {list_cursor.ListMenuOption<BattleMenuContext, string>} = {}
                    -- if target in range
                    if any_target_in_range(msb.battle_map, ctx) then -- TODO: global state
                        pt.add(options, {
                            text = "Attack",
                            next_state = "SELECT_TARGET"
                        })
                    end

                    local nearby_interactions = msb.battle_map:get_nearby_interactions(ctx.destination.point)
                    for _, interaction in ipairs(nearby_interactions) do
                        pt.add(options, {
                            text = interaction.interaction_text,
                            send_command = "TACTICS_INTERACTION",
                            set_selected_context = function(_: BattleMenuContext, mc: BattleMainMenuContext)
                                mc.selected_script = {
                                    script_id = interaction.script_id,
                                    target_unit = interaction.target_unit,
                                    target_tile = interaction.target_tile,
                                }
                            end
                        })
                    end

                    pt.add(options, {
                        text = "Wait",
                        send_command = "END_UNIT_TURN"
                    })

                    --- currently disabled as items aren't mechanically interesting yet
                    -- pt.add(options, {
                    --     text = "Items",
                    --     next_state = "SELECT_ITEM"
                    -- })
                    
                    return options
                end
            }),
            ["SELECT_TARGET"] = grid_cursor.definition({
                previous_state = "SELECT_ACTION",
                set_selected_context = function(s: grid_cursor.GridMenuCursor<BattleMenuContext>, msb: BattleMenuContext, ctx: BattleMainMenuContext)
                    ctx.target_unit = { unit = msb.battle_map:get_at_tile(s.point)}
                end,
                validator =  function (s: grid_cursor.GridMenuCursor<BattleMenuContext>, msb: BattleMenuContext, ctx: BattleMainMenuContext): boolean
                    return validate_tile_is_in_unit_attack_range(msb.battle_map, ctx.acting_unit.unit, ctx.destination.point, s.point) 
                end,
                send_command = "ATTACK_UNIT",
                get_legal_tiles = function (msb: BattleMenuContext, ctx: BattleMainMenuContext): array_2d.Array2D<grid_cursor.MenuTileHighlight>
                    return msb.tactics_engine:tiles_with_distance_from_unit_attacks(ctx.acting_unit.unit, ctx.destination.point)
                end
            }),
            ["SELECT_ITEM"] = list_cursor.definition({
                previous_state = "SELECT_ACTION",
                set_selected_context = function(s: list_cursor.ListMenuCursor<BattleMenuContext, string>, _msb: BattleMenuContext, ctx: BattleMainMenuContext)
                    ctx.selected_item = {
                        index = s.i,
                        item = ctx.acting_unit.unit.character.inventory:get_items()[s.i]
                    }
                end,
                get_options = function(_msb: BattleMenuContext, ctx: BattleMainMenuContext): {list_cursor.ListMenuOption<BattleMenuContext, string>}
                        local character = ctx.acting_unit.unit
                        local items = character.character.inventory:get_items()

                        local options = {}
                        for _,item in ipairs(items) do
                            pt.add(options, {
                                text = item:get_name(),
                                next_state = "SELECT_ITEM_ACTION"
                            })
                        end
                        return options
                end
            }),
            ["SELECT_ITEM_ACTION"] = list_cursor.definition({
                previous_state = "SELECT_ITEM",
                get_options = function(_msb: BattleMenuContext, ctx: BattleMainMenuContext): {list_cursor.ListMenuOption<BattleMenuContext, string>}
                        local character = ctx.acting_unit.unit
                        local inventory = character.character.inventory
                        local items = inventory:get_items()
                        local item = ctx.selected_item.item
                        local index = ctx.selected_item.index

                        if inventory:get_items()[index] == nil then
                            return {}
                        end
                        
                        local options = {}

                        -- TODO: consumables
                        if item:get_equip_slot() ~= "NONE" then
                            if inventory:is_equipped(index) then
                                pt.add(options, {
                                    text = "Unequip",
                                    send_command = "INVENTORY_UNEQUIP_ITEM",
                                    next_state = "SELECT_ITEM_ACTION",
                                })
                            else
                                pt.add(options, {
                                    text = "Equip",
                                    send_command = "INVENTORY_EQUIP_ITEM",
                                    next_state = "SELECT_ITEM_ACTION",
                                })
                            end
                        end

                        if #items > 0 then
                            pt.add(options, {
                                text = "Move",
                            })
                        end
                        pt.add(options, {
                            text = "Discard",
                            send_command = "INVENTORY_DISCARD_ITEM",
                            next_state = "SELECT_ITEM",
                        })
                        
                        return options
                end
            }),
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
