require("src/debug")
require("src/types")
require("src/menu/types")
require("src/menu/menu_manager")
require("src/battle/tactics/tactics_engine")
require("src/joypad")
require("src/battle/pathfinding")
require("src/systems/service")
require("src/menu/menu_manager")


local record BattleMenuServiceBundle
    is MenuServiceBundle
    tactics_engine: TacticsEngine
    battle_map: BattleMap
end

global record BattleMenuManager
    is TransientGameService, MenuManager<BattleMenuServiceBundle>
    where self.id == 'battle_menu_manager'

end

-- kind
-- selected_data_mapper -- returns (success bool, data) to store
-- select_transition
local MENU_DATA: { MenuId: MenuDefinition } = {
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = GridMenuDefinition.new({
                set_selected_context = function(s: GridMenuSelection, msb: BattleMenuServiceBundle, ctx: MenuContext)
                    ctx.acting_unit = { unit = msb.battle_map:get_at_tile(s.point)}
                end,
                validator = function (s: MenuSelection, msb: BattleMenuServiceBundle, _ctx: MenuContext): boolean
                    return msb.tactics_engine:grid_selection_is_available_player(s) end,
                next_state = "SELECT_DESTINATION"
            }),
            ["SELECT_DESTINATION"] = GridMenuDefinition.new({
                set_selected_context = function(s: GridMenuSelection, _msb: BattleMenuServiceBundle, ctx: MenuContext)
                    ctx.destination = { point = s.point:copy(), path = s.path }
                end,
                validator = function (s: MenuSelection, msb: BattleMenuServiceBundle, ctx: MenuContext): boolean
                    assert(s is GridMenuSelection)
                     return msb.tactics_engine:grid_selection_is_empty_or_acting_unit(s, ctx)
                        and s.legal_tiles:get_point(s.point) ~= nil
                        and s.legal_tiles:get_point(s.point).valid_selection
                end,
                next_state = "SELECT_ACTION",
                previous_state = "SELECT_UNIT",
                get_legal_tiles = function (msb: BattleMenuServiceBundle, ctx: MenuContext): Array2D<MenuTileHighlight>
                    return msb.tactics_engine:tiles_in_movement_and_attack_range(ctx)
                end
            }),
            ["SELECT_ACTION"] = ListMenuDefinition.new({
                previous_state = "SELECT_DESTINATION",
                get_options = function(msb: BattleMenuServiceBundle, ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}
                    -- if target in range
                    if msb.tactics_engine:any_target_in_range(ctx) then -- TODO: global state
                        add(options, {
                            text = "Attack",
                            next_state = "SELECT_TARGET"
                        })
                    end

                    add(options, {
                        text = "Wait",
                        send_command = "MOVE_AND_WAIT"
                    })

                    add(options, {
                        text = "Items",
                        next_state = "SELECT_ITEM"
                    })

                    return options
                end
            }),
            ["SELECT_TARGET"] = GridMenuDefinition.new({
                previous_state = "SELECT_ACTION",
                set_selected_context = function(s: GridMenuSelection, msb: BattleMenuServiceBundle, ctx: MenuContext)
                    ctx.target_unit = { unit = msb.battle_map:get_at_tile(s.point)}
                end,
                validator =  function (s: MenuSelection, msb: BattleMenuServiceBundle, ctx: MenuContext): boolean
                    return msb.tactics_engine:validate_tile_is_in_unit_attack_range(s, ctx) 
                end,
                send_command = "MOVE_AND_ATTACK",
                get_legal_tiles = function (msb: BattleMenuServiceBundle, ctx: MenuContext): Array2D<MenuTileHighlight>
                    return msb.tactics_engine:tiles_with_distance_from_unit_attacks(ctx)
                end
            }),
            ["SELECT_ITEM"] = ListMenuDefinition.new({
                previous_state = "SELECT_ACTION",
                set_selected_context = function(s: VerticalListMenuSelection, _msb: BattleMenuServiceBundle, ctx: MenuContext)
                    ctx.selected_item = {
                        index = s.i,
                        item = ctx.acting_unit.unit.character.inventory:get_items()[s.i]
                    }
                end,
                get_options = function(_msb: BattleMenuServiceBundle, ctx: MenuContext): {MenuOption}
                        local character = ctx.acting_unit.unit
                        local items = character.character.inventory:get_items()

                        local options = {}
                        for i,item in ipairs(items) do
                            add(options, {
                                text = item:get_name(),
                                next_state = "SELECT_ITEM_ACTION"
                            })
                        end
                        return options
                end
            }),
            ["SELECT_ITEM_ACTION"] = ListMenuDefinition.new({
                previous_state = "SELECT_ITEM",
                get_options = function(_msb: BattleMenuServiceBundle, ctx: MenuContext): {MenuOption}
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
                                add(options, {
                                    text = "Unequip",
                                    send_command = "INVENTORY_UNEQUIP_ITEM",
                                    next_state = "SELECT_ITEM_ACTION",
                                })
                            else
                                add(options, {
                                    text = "Equip",
                                    send_command = "INVENTORY_EQUIP_ITEM",
                                    next_state = "SELECT_ITEM_ACTION",
                                })
                            end
                        end

                        if #items > 0 then
                            add(options, {
                                text = "Move",
                            })
                        end
                        add(options, {
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

function BattleMenuManager.new(): BattleMenuManager
    return BaseMenuManager.new(
        "battle_menu_manager",
        {
            "tactics_engine",
            "battle_map",
            "event_bus"
        },
        MENU_DATA,
        function(services: { ServiceId: GameService }): BattleMenuServiceBundle
            return {
                tactics_engine = services.tactics_engine as TacticsEngine,
                battle_map = services.battle_map as BattleMap,
            }
        end
    ) as BattleMenuManager
end

return BattleMenuManager
