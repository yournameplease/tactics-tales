require("src/debug")
require ("src/types")
require ("src/menu/types")
require ("src/menu/menu_selection")
-- TODO: tactics is only needed for lazy dijkstra animation.
require("src/battle/tactics/tactics_engine")
require("src/joypad")
require("src/battle/tile_manager")


local record MenuServiceBundle
    tactics_engine: TacticsEngine
    battle_state: BattleState
    tile_manager: TileManager
end

global record SelectionHistory
    step: MenuStep
    selection: MenuSelection
end

global record MenuManager
    menu_state: MenuState
    menu_ctx: MenuContext
    menu_selection: MenuSelection
    selection_history: { SelectionHistory }

    services: MenuServiceBundle
    event_bus: EventBus
end

function MenuManager.new(
    tactics_engine: TacticsEngine,
    battle_state: BattleState,
    tile_manager: TileManager,
    event_bus: EventBus
): MenuManager
    local self: MenuManager = setmetatable({}, { __index = MenuManager })

    self.menu_state = {
        point = TilePoint.of(0, 0)
    }
    self.menu_ctx = {}
    self.menu_selection = {}
    self.selection_history = {}

    self.services = {
        tactics_engine = tactics_engine,
        battle_state = battle_state,
        tile_manager = tile_manager,
    }
    self.event_bus = event_bus

    return self
end

global interface MenuStepDefinition
    type: MenuType
end

global record GridMenuDefinition
    is MenuStepDefinition
    where self.type == "CURSOR_GRID"
    set_selected_context: function(GridMenuSelection, MenuServiceBundle, MenuContext)
    validator: function(GridMenuSelection, MenuServiceBundle, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
    get_legal_tiles: function(MenuServiceBundle, MenuContext): Array2D<MenuTileHighlight>
end

function GridMenuDefinition.new(props: GridMenuDefinition): GridMenuDefinition
    return props
end

global record ListMenuDefinition
    is MenuStepDefinition
    where self.type == "CURSOR_VERTICAL_LIST" -- or horizontal
    set_selected_context: function(VerticalListMenuSelection, MenuServiceBundle, MenuContext)
    get_options: function(MenuServiceBundle, MenuContext): {MenuOption}
end

function ListMenuDefinition.new(props: ListMenuDefinition): ListMenuDefinition
    return props
end

global record MenuDefinition
    initial_step: MenuStep
    steps: { MenuStep: MenuStepDefinition }
end

-- kind
-- selected_data_mapper -- returns (success bool, data) to store
-- select_transition
local MENU_DATA: { MenuId: MenuDefinition } = {
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = GridMenuDefinition.new({
                type = "CURSOR_GRID",
                set_selected_context = function(s: GridMenuSelection, msb: MenuServiceBundle, ctx: MenuContext)
                    ctx.acting_unit = { unit = msb.battle_state:get_at_tile(s.point)}
                end,
                validator = function (s: MenuSelection, msb: MenuServiceBundle, _ctx: MenuContext): boolean
                    return msb.tactics_engine:grid_selection_is_available_player(s) end,
                next_state = "SELECT_DESTINATION"
            }),
            ["SELECT_DESTINATION"] = GridMenuDefinition.new({
                type = "CURSOR_GRID",
                set_selected_context = function(s: GridMenuSelection, msb: MenuServiceBundle, ctx: MenuContext)
                    ctx.destination = { point = s.point:copy(), path = s.path }
                end,
                validator = function (s: MenuSelection, msb: MenuServiceBundle, ctx: MenuContext): boolean
                    assert(s is GridMenuSelection)
                     return msb.tactics_engine:grid_selection_is_empty_or_acting_unit(s, ctx)
                        and s.legal_tiles:get_point(s.point) ~= nil
                        and s.legal_tiles:get_point(s.point).valid_selection
                end,
                next_state = "SELECT_ACTION",
                get_legal_tiles = function (msb: MenuServiceBundle, ctx: MenuContext): Array2D<MenuTileHighlight>
                    return msb.tactics_engine:tiles_in_movement_and_attack_range(ctx)
                end
            }),
            ["SELECT_ACTION"] = ListMenuDefinition.new({
                type = "CURSOR_VERTICAL_LIST",
                get_options = function(msb: MenuServiceBundle, ctx: MenuContext): {MenuOption}
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
                type = "CURSOR_GRID",
                set_selected_context = function(s: GridMenuSelection, msb: MenuServiceBundle, ctx: MenuContext)
                    ctx.target_unit = { unit = msb.battle_state:get_at_tile(s.point)}
                end,
                validator =  function (s: MenuSelection, msb: MenuServiceBundle, ctx: MenuContext): boolean
                    return msb.tactics_engine:validate_tile_is_in_unit_attack_range(s, ctx) 
                end,
                send_command = "MOVE_AND_ATTACK",
                get_legal_tiles = function (msb: MenuServiceBundle, ctx: MenuContext): Array2D<MenuTileHighlight>
                    return msb.tactics_engine:tiles_with_distance_from_unit_attacks(ctx)
                end
            }),
            ["SELECT_ITEM"] = ListMenuDefinition.new({
                type = "CURSOR_VERTICAL_LIST",
                set_selected_context = function(s: VerticalListMenuSelection, msb: MenuServiceBundle, ctx: MenuContext)
                    ctx.selected_item = {
                        index = s.i,
                        item = ctx.acting_unit.unit.character.inventory:get_items()[s.i]
                    }
                end,
                get_options = function(msb: MenuServiceBundle, ctx: MenuContext): {MenuOption}
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
                type = "CURSOR_VERTICAL_LIST",
                get_options = function(msb: MenuServiceBundle, ctx: MenuContext): {MenuOption}
                        local character = ctx.acting_unit.unit
                        local inventory = character.character.inventory
                        local items = inventory:get_items()
                        local item = ctx.selected_item.item
                        local index = ctx.selected_item.index

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


function MenuManager:populate_menu_state(new_step: MenuStep)
    self.menu_state.step = new_step

    local menu_data = MENU_DATA[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]
    if new_step_data is GridMenuDefinition then
        local new_selection = GridMenuSelection.new(
            self.menu_state.point:copy(),
            16,
            16
        )
        if new_step_data.get_legal_tiles ~= nil then
            new_selection.legal_tiles = new_step_data.get_legal_tiles(self.services, self.menu_ctx)
        else
            new_selection.legal_tiles = nil
        end
        self.menu_selection = new_selection
    elseif new_step_data is ListMenuDefinition then
        local new_selection = VerticalListMenuSelection.new(
            0,
            new_step_data.get_options(self.services, self.menu_ctx)
        )
        self.menu_selection = new_selection
    else
        error("not implemented")
    end
end

function MenuManager:handle_menu_select()
    LOG.debug("Selecting "..self.menu_state.menu_id .. ":" .. self.menu_state.step)
    local menu_data = MENU_DATA[self.menu_state.menu_id]
    local step_data = menu_data.steps[self.menu_state.step]

    local next_state: MenuStep
    local send_command: GameEvent

    local menu_selection = self.menu_selection

    if step_data is GridMenuDefinition then
        assert(menu_selection is GridMenuSelection)
        local validation = step_data.validator(menu_selection, self.services, self.menu_ctx)
        if not validation then return end

        if self.menu_ctx.acting_unit ~= nil and self.menu_state.step == "SELECT_DESTINATION" then
            local acting_unit = self.menu_ctx.acting_unit.unit
            local costs = self.services.tile_manager:calculate_all_tile_costs(acting_unit.tile.x, acting_unit.tile.y, 0, 999)
            local path = self.services.tile_manager:get_path_to_tile(costs, menu_selection.point)
            menu_selection.path = path
            LOG.debug("Path length: ", #path)
            for _, p in ipairs(path) do
                LOG.debug("Path point", p.x, p.y)
            end
        end

        self.menu_state.point = menu_selection.point:copy()
        step_data.set_selected_context(menu_selection, self.services, self.menu_ctx)
        next_state = step_data.next_state
        send_command = step_data.send_command
    elseif step_data is ListMenuDefinition then
        assert(menu_selection is VerticalListMenuSelection)
        if step_data.set_selected_context ~= nil then
            step_data.set_selected_context(menu_selection, self.services, self.menu_ctx)
        end
        next_state = menu_selection.options[menu_selection.i].next_state
        send_command = menu_selection.options[menu_selection.i].send_command
    end

    add(self.selection_history, {
        step = self.menu_state.step,
        selection = self.menu_selection
    })

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end

    if send_command ~= nil then
        LOG.info("Emitting menu command ", send_command)
        self.event_bus:emit(send_command, self.menu_ctx)
    end
end

function MenuManager:handle_menu_back()
    if #self.selection_history == 0 then return end

    local previous_step = self.selection_history[#self.selection_history]
    -- TODO: use this to get last cursor position
    -- or, just push the entire active cursor onto a list
    self.selection_history[#self.selection_history] = nil
    self:populate_menu_state(previous_step.step)
    self.menu_selection = previous_step.selection
end


function MenuManager:set_menu(menu_id: MenuId)
    self.menu_state.menu_id = menu_id
    self.selection_history = {}
    local step = MENU_DATA[menu_id].initial_step
    self:populate_menu_state(step)
end


function MenuManager:update(joy: Joypad)
    if joy.lp then
        self.event_bus:emit("TACTICS_END_PLAYER_TURN")
    elseif joy.bp then
        self:handle_menu_back()
    elseif joy.ap then
        self:handle_menu_select()
    else
        self.menu_selection:update(joy)
    end
end

return MenuManager
