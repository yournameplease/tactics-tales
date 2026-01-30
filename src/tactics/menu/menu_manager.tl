local point = require("src/tactics/util/point")
local menu_types = require ("src/tactics/menu/types")
local input_service = require("src/tactics/joypad")
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse
local input_context = require("src/tactics/input/input_context")
local InputContext = input_context.InputContext
local event_bus = require("src/tactics/systems/event_bus")
local event_writer = require("src/tactics/systems/event_bus/event_writer")
local menu_cursor = require("src/tactics/menu/menu_cursor")
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local mouse_menu_selection = require("src/tactics/menu/menu_cursor").mouse_selection

local record SelectionHistory<GameContext>
    step: menu_types.MenuStep
    selection: menu_cursor.MenuCursor<GameContext>
end

local record MenuDefinition<GameContext>
    initial_step: menu_types.MenuStep
    steps: { menu_types.MenuStep: menu_cursor.MenuStepDefinition<GameContext> }
end

local interface MenuManager<GameContext>
    
    menu_definitions: { menu_types.MenuId: MenuDefinition }

    menu_state: menu_types.MenuState
    menu_ctx: MenuContext
    menu_cursor: menu_cursor.MenuCursor<GameContext>
    selection_history: { SelectionHistory<GameContext> }

    game_ctx: GameContext
    event_writer: event_writer.EventWriter

    populate_menu_state: function(self, new_step: menu_types.MenuStep)
    handle_menu_select: function(self)
    handle_menu_back: function(self)
    clear_menu: function(self)
    set_menu: function(self, menu_id: menu_types.MenuId)
    update: function(self, input: InputContext)
end

local record BaseMenuManager<GameContext>
    is MenuManager<GameContext>

    menu_definitions: { menu_types.MenuId: MenuDefinition<GameContext> }
end

local menu_manager = {
    MenuManager = MenuManager,
    SelectionHistory = SelectionHistory,
    MenuDefinition = MenuDefinition,
}

function menu_manager.new<GameContext>(
    menu_definitions: { menu_types.MenuId: MenuDefinition },
    ctx: GameContext,
    bus: event_bus.EventBus
): MenuManager<GameContext>
    local self: BaseMenuManager<GameContext> = setmetatable({}, { __index = BaseMenuManager })

    self.menu_definitions = menu_definitions

    self.menu_state = {
        point = point.of(0, 0)
    }
    self.menu_ctx = {
        metadata = {}
    }
    self.menu_cursor = {}
    self.selection_history = {}

    self.game_ctx = ctx
    self.event_writer = event_writer.new(bus)

    return self
end

function BaseMenuManager:populate_menu_state(new_step: menu_types.MenuStep)
    self.menu_state.step = new_step

    local menu_data = self.menu_definitions[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]
    
    self.menu_cursor = new_step_data:to_cursor(self.game_ctx, self.menu_ctx, self.menu_state)
end

function BaseMenuManager:handle_menu_select()
    log.debug("Selecting "..self.menu_state.menu_id .. ":" .. self.menu_state.step)

    local next_state = self.menu_cursor:handle_select(self.game_ctx, self.menu_ctx, self.menu_state)
    
    pt.add(self.selection_history, {
        step = self.menu_state.step,
        selection = self.menu_cursor
    })

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end
end

function BaseMenuManager:handle_menu_back()
    self.menu_cursor:handle_back(self.game_ctx, self.menu_ctx)

    local previous_step = self.menu_definitions[self.menu_state.menu_id].steps[self.menu_state.step]
        .previous_state

    if previous_step == nil then
        return
    end
    log.debug("Backing out of "..self.menu_state.menu_id .. " to " .. previous_step)
    while #self.selection_history > 0 and
        self.selection_history[#self.selection_history].step ~= previous_step do
        self.selection_history[#self.selection_history] = nil
    end
    self:populate_menu_state(previous_step)
    if #self.selection_history > 0 then
        self.menu_cursor = self.selection_history[#self.selection_history].selection
    end
end


function BaseMenuManager:clear_menu()
    self.menu_state.menu_id = nil
    self.menu_ctx = nil
    self.selection_history = {}
end

function BaseMenuManager:set_menu(menu_id: menu_types.MenuId)
    local definition = self.menu_definitions[menu_id]
    self.menu_state.menu_id = menu_id
    self.menu_ctx = {
        metadata = {}
    }
    self.selection_history = {}
    local step = definition.initial_step
    self:populate_menu_state(step)
end


function BaseMenuManager:update(input: InputContext)
    local btn_skip_turn = false
    local btn_select = false
    local btn_back = false
    
    if input is input_context.JoypadContext then
        btn_skip_turn = input.joypad.lp      
        btn_select = input.joypad.ap      
        btn_back = input.joypad.bp        
    elseif input is input_context.MouseContext then
        btn_select = input.mouse.mlp
        btn_back = input.mouse.mrp
    else
        unexpected(input.type)
    end

    if btn_skip_turn then
        -- DEBUG Only for now.  consider where to put
        self.event_writer:emit("TACTICS_FINISH_SIDE_ACTIONS", {})
    elseif btn_back then
        self:handle_menu_back()
    elseif btn_select then
        self:handle_menu_select()
    else
        input_context.handle_update(
            input,
            function(joy: Joypad) self.menu_cursor:update_joy(joy) end,
            function(
                mouse: Mouse,
                hovered: mouse_menu_selection.MenuMouseSelection
            ) self.menu_cursor:update_mouse(mouse, hovered) end
        )
    end
end

return menu_manager
