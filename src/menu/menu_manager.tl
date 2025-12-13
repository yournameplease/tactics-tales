require("src/debug")
require ("src/types")
require ("src/menu/types")
require("src/joypad")
require("src/systems/service")
require("src/battle/tactics/battle_unit")
require("src/battle/battle_context")
require("src/game_context")
require("src/systems/service/game_service_bundle")
require("src/menu/menu_cursor")


global record MenuOption
    text: string
    next_state: MenuStep
    send_command: GameEvent
end

global record GridMenuCursor
    is MenuCursor
    where self.type == "CURSOR_GRID"
    point: TilePoint
    x_max: integer
    y_max: integer
    path: { TilePoint }
    legal_tiles: Array2D<MenuTileHighlight>
end

function GridMenuCursor.new(point: TilePoint, x_max: integer, y_max: integer): GridMenuCursor
    local self: GridMenuCursor = {
        type = "CURSOR_GRID",
        point = point, 
        x_max = x_max,
        y_max = y_max
    }
    return setmetatable(self, { __index = GridMenuCursor })
end

function GridMenuCursor:update(joy: Joypad)
        self.point.x = mid(0, self.point.x + joy.dxp, self.x_max - 1)
        self.point.y = mid(0, self.point.y + joy.dyp, self.y_max - 1)
end

global enum ListDirection
    "vertical"
    "horizontal"
end

global record ListMenuCursor
    is MenuCursor
    where self.type == "CURSOR_LIST"
    i: integer
    options: { MenuOption }
    direction: ListDirection
    wrap: boolean
end

function ListMenuCursor.new(i: integer, options: {MenuOption}, wrap: boolean): ListMenuCursor
    local self: ListMenuCursor = {
        type = "CURSOR_LIST",
        i = i,
        options = options,
        direction = "vertical",
        wrap = wrap,
    }
    return setmetatable(self, { __index = ListMenuCursor })
end

function ListMenuCursor:update(joy: Joypad)
    local new_i = self.i
    if self.direction == "vertical" then
        new_i = new_i + joy.dyp
    elseif self.direction == "horizontal" then
        new_i = new_i + joy.dxp
    else
        error()
    end
    
    if self.wrap then
        self.i = new_i % #self.options + 1
    else
        self.i = mid(1, new_i, #self.options)
    end
end

global record MenuMultipleOptionDefinition
    text: string -- label
    definition: MenuStepDefinition
    must_select: boolean -- true if must be picked before using.  Default to false
end

global record MenuMultipleOptionSelection
    text: string -- label
    selection: MenuCursor
    must_select: boolean -- true if must be picked before using.  Default to false
end

global enum MultipleOptionsDirection
    "vertical"
    "horizontal"
    "select"
end

global record MultipleOptionsMenuCursor
    is MenuCursor
    where self.type == "CURSOR_MULTIPLE_OPTIONS"
    i: integer
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    is_option_selected: boolean -- if the current selection has been selected.  Needed if the selection is must_select
    options: { MenuMultipleOptionSelection }
end

function MultipleOptionsMenuCursor.new(i: integer, options: {MenuDefinition}): MultipleOptionsMenuCursor
    local self: MultipleOptionsMenuCursor = {
        type = "CURSOR_MULTIPLE_OPTIONS",
        i = i,
        options = List.do_map(
            options,
            function(o: MenuDefinition): MenuCursor
                return MenuCursor.of(o)
            end
        ),
    }
    return setmetatable(self, { __index = MultipleOptionsMenuCursor })
end

function MultipleOptionsMenuCursor:update_option(joy: Joypad)
    local current_selection = self.options[self.i]
    if self.is_option_selected or not current_selection.must_select then
        current_selection.selection:update(joy)
    end
end

function MultipleOptionsMenuCursor:update(joy: Joypad)
    local new_i = self.i
    if self.primary_direction == "vertical" then
        if joy.dyp ~= 0 then
            new_i = new_i + joy.dyp
        else
            self:update_option(joy)
        end
    elseif self.primary_direction == "horizontal" then
        if joy.dxp ~= 0 then
            new_i = new_i + joy.dxp
        else
            self:update_option(joy)
        end
    elseif self.primary_direction == "select" then
        -- handled by handle_menu_select
    end
    
    if self.wrap then
        self.i = new_i % #self.options + 1
    else
        self.i = mid(1, new_i, #self.options)
    end
end

global record ButtonAdvanceCursor
    is MenuCursor
    where self.type == "CURSOR_BUTTON_ADVANCE"
end

function ButtonAdvanceCursor.new(): ButtonAdvanceCursor
    local self: ButtonAdvanceCursor = {
        type = "CURSOR_BUTTON_ADVANCE",
    }
    return setmetatable(self, { __index = ButtonAdvanceCursor })
end

function ButtonAdvanceCursor:update(_joy: Joypad)
end

global record SelectionHistory
    step: MenuStep
    selection: MenuCursor
end

global interface MenuStepDefinition
    type: MenuType
    previous_state: MenuStep
end

global record GridMenuDefinition<MSB is GameContext>
    is MenuStepDefinition
    where self.type == "CURSOR_GRID"

    set_selected_context: function(GridMenuCursor, MSB, MenuContext)
    validator: function(GridMenuCursor, MSB, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
    get_legal_tiles: function(MSB, MenuContext): Array2D<MenuTileHighlight>
end

function GridMenuDefinition.new(props: GridMenuDefinition<MSB>): GridMenuDefinition<MSB>
    props.type = "CURSOR_GRID"
    return props
end

global record ListMenuDefinition<MSB is GameContext>
    is MenuStepDefinition
    where self.type == "CURSOR_LIST"
    set_selected_context: function(ListMenuCursor, MSB, MenuContext)
    get_options: function(MSB, MenuContext): {MenuOption}
end

function ListMenuDefinition.new(props: ListMenuDefinition<MSB>): ListMenuDefinition<MSB>
    props.type = "CURSOR_LIST"
    return props
end

global record ButtonAdvanceMenuDefinition<MSB is GameContext>
    is MenuStepDefinition
    where self.type == "CURSOR_BUTTON_ADVANCE" 
    next_state: MenuStep
    send_command: GameEvent
end

function ButtonAdvanceMenuDefinition.new(props: ButtonAdvanceMenuDefinition<MSB>): ButtonAdvanceMenuDefinition<MSB>
    props.type = "CURSOR_BUTTON_ADVANCE"
    return props
end

global record MenuDefinition
    initial_step: MenuStep
    steps: { MenuStep: MenuStepDefinition }
end

global interface MenuManager<MSB is GameContext>
    
    menu_definitions: { MenuId: MenuDefinition }

    menu_state: MenuState
    menu_ctx: MenuContext
    menu_cursor: MenuCursor
    selection_history: { SelectionHistory }

    game_ctx: MSB
    event_bus: EventBus

    init: function(self, service_manager: ServiceManager, services: { ServiceId: GameService }) 
    -- new: function(
    --     menu_definitions: { MenuId: MenuDefinition },
    --     get_menu_service_bundle: function(services: { ServiceId: GameService }): MSB
    -- ): MenuManager<MSB>
    populate_menu_state: function(self, new_step: MenuStep)
    handle_menu_select: function(self)
    handle_menu_back: function(self)
    set_menu: function(self, menu_id: MenuId)
    update: function(self, joy: Joypad)
end

global record BaseMenuManager<BMSB is GameContext>
    is MenuManager<BMSB>

    menu_definitions: { MenuId: MenuDefinition }
end

function BaseMenuManager.new(
    menu_definitions: { MenuId: MenuDefinition },
    ctx: GameContext
): MenuManager<BMSB>
    local self: BaseMenuManager<BMSB> = setmetatable({}, { __index = BaseMenuManager })

    self.menu_definitions = menu_definitions

    self.menu_state = {
        point = TilePoint.of(0, 0)
    }
    self.menu_ctx = {}
    self.menu_cursor = {}
    self.selection_history = {}

    self.game_ctx = ctx
    self.event_bus = ctx.services.event_bus as EventBus

    return self
end

function BaseMenuManager:populate_menu_state(new_step: MenuStep)
    self.menu_state.step = new_step

    local menu_data = self.menu_definitions[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]
    if new_step_data is GridMenuDefinition<BMSB> then
        local new_selection = GridMenuCursor.new(
            self.menu_state.point:copy(),
            16,
            16
        )
        if new_step_data.get_legal_tiles ~= nil then
            new_selection.legal_tiles = new_step_data.get_legal_tiles(self.game_ctx, self.menu_ctx)
        else
            new_selection.legal_tiles = nil
        end
        self.menu_cursor = new_selection
    elseif new_step_data is ListMenuDefinition<BMSB> then
        local new_selection = ListMenuCursor.new(
            0,
            new_step_data.get_options(self.game_ctx, self.menu_ctx)
        )
        self.menu_cursor = new_selection
    else
        error("not implemented")
    end
end

function BaseMenuManager:handle_menu_select()
    LOG.debug("Selecting "..self.menu_state.menu_id .. ":" .. self.menu_state.step)
    local menu_data = self.menu_definitions[self.menu_state.menu_id]
    local step_data = menu_data.steps[self.menu_state.step]

    local next_state: MenuStep
    local send_command: GameEvent

    local menu_cursor = self.menu_cursor

    if step_data is GridMenuDefinition<BMSB> then
        assert(menu_cursor is GridMenuCursor)
        local validation = step_data.validator(menu_cursor, self.game_ctx, self.menu_ctx)
        if not validation then return end

        if self.menu_ctx.acting_unit ~= nil and self.menu_state.step == "SELECT_DESTINATION" then
            -- TODO: keep path in the cursor data, and let battle menu manager do dijkstra
            menu_cursor.path = { TilePoint.of(0, 0)  }
        end

        self.menu_state.point = menu_cursor.point:copy()
        step_data.set_selected_context(menu_cursor, self.game_ctx, self.menu_ctx)
        next_state = step_data.next_state
        send_command = step_data.send_command
    elseif step_data is ListMenuDefinition<BMSB> then
        assert(menu_cursor is ListMenuCursor)
        if step_data.set_selected_context ~= nil then
            step_data.set_selected_context(menu_cursor, self.game_ctx, self.menu_ctx)
        end
        next_state = menu_cursor.options[menu_cursor.i].next_state
        send_command = menu_cursor.options[menu_cursor.i].send_command
    elseif step_data is ButtonAdvanceMenuDefinition<BMSB> then
        next_state = step_data.next_state
        send_command = step_data.send_command
    else
        error("Unexpected menu state: "..step_data.type)
    end

    add(self.selection_history, {
        step = self.menu_state.step,
        selection = self.menu_cursor
    })

    if send_command ~= nil then
        LOG.info("Emitting menu command ", send_command)
        self.event_bus:emit(send_command, self.menu_ctx)
    end

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end
end

function BaseMenuManager:handle_menu_back()
    local previous_step = self.menu_definitions[self.menu_state.menu_id].steps[self.menu_state.step]
        .previous_state

    if previous_step == nil then
        return
    end
    while #self.selection_history > 1 and
        self.selection_history[#self.selection_history].step ~= previous_step do
        self.selection_history[#self.selection_history] = nil
    end
    self:populate_menu_state(previous_step)
    self.menu_cursor = self.selection_history[#self.selection_history].selection
end


function BaseMenuManager:set_menu(menu_id: MenuId)
    self.menu_state.menu_id = menu_id
    self.selection_history = {}
    local step = self.menu_definitions[menu_id].initial_step
    self:populate_menu_state(step)
end


function BaseMenuManager:update(joy: Joypad)
    if joy.lp then
        -- DEBUG Only for now.  consider where to put
        self.event_bus:emit("TACTICS_END_PLAYER_TURN")
    elseif joy.bp then
        self:handle_menu_back()
    elseif joy.ap then
        self:handle_menu_select()
    else
        self.menu_cursor:update(joy)
    end
end

return MenuManager
