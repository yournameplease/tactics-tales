---@brief
--- A generic manager for menu systems. It handles state transitions,
--- history, and dispatches input to the active menu cursor.

local menu_types = require ("src.tactics.menu.types")
local input_service = require("src.tactics.joypad")
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse
local input_context = require("src.tactics.input.input_context")
local InputContext = input_context.InputContext
local event_bus = require("src.tactics.systems.event_bus")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local MenuSignal = menu_signal.MenuSignal
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local record SelectionHistory
    step: menu_types.MenuStep
end

local record MenuStep
	previous_step: string
	back_handler: function(GameContext, MenuContext)
	node: menu_cursor.MenuNode
end

local record MenuStepDefinition
	previous_step: string
	back_handler: function(GameContext, MenuContext)
	node: menu_cursor.MenuNodeDefinition
end

local menu_step_definition = {}

function menu_step_definition.of_node(
	node_definition: menu_cursor.MenuNodeDefinition
): MenuStepDefinition
	return setmetatable({
		node = node_definition,
	}, {
		__index = MenuStepDefinition
	})
end

function MenuStepDefinition:with_previous_step(step_id: string): MenuStepDefinition
    self.previous_step = step_id
    return self
end

function MenuStepDefinition:handle_back(
	back_handler: function(GameContext, MenuContext)
): MenuStepDefinition
	self.back_handler = back_handler
	return self
end

function MenuStepDefinition:build(
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
): MenuStep
    local out: MenuStep = {
        node = self.node:to_cursor(game_ctx, menu_ctx, menu_state),
    }
    return setmetatable(out, { __index = function(_: any, k: string): any 
            if (MenuStep as {string: any})[k] then
                return (MenuStep as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
    })
end

local record MenuDefinition
    initial_step: menu_types.MenuStep
    steps: { menu_types.MenuStep: MenuStepDefinition }
end

local record SerializedMenu
    menu_id: menu_types.MenuId
    step: menu_types.MenuStep
    node: menu_cursor.SerializedMenu
end

local interface MenuManager
    
    menu_definitions: { menu_types.MenuId: MenuDefinition }

    menu_state: menu_types.MenuState
    menu_ctx: MenuContext
    menu_step: MenuStep
    selection_history: { SelectionHistory }

    game_ctx: GameContext
    event_writer: event_writer.EventWriter

    populate_menu_state: function(self, new_step: menu_types.MenuStep)
    handle_menu_select: function(self)
    handle_menu_back: function(self)
    clear_menu: function(self)
    set_menu: function(self, menu_id: menu_types.MenuId)
    update: function(self, input: InputContext)
    serialize: function(self): SerializedMenu
end

local record BaseMenuManager
    is MenuManager

    menu_definitions: { menu_types.MenuId: MenuDefinition }
end

local menu_manager = {
    MenuManager = MenuManager,
    SelectionHistory = SelectionHistory,
    MenuDefinition = MenuDefinition,
    MenuStepDefinition = MenuStepDefinition,

    definition = {
        step = menu_step_definition,
    },
}

function menu_manager.new(
    menu_definitions: { menu_types.MenuId: MenuDefinition },
    ctx: GameContext,
    bus: event_bus.EventBus
): MenuManager
    local self: BaseMenuManager = setmetatable({}, { __index = BaseMenuManager })

    self.menu_definitions = menu_definitions

    self.menu_state = {}
    self.menu_ctx = {
        metadata = {}
    }
    self.selection_history = {}

    self.game_ctx = ctx
    self.event_writer = event_writer.new(bus)

    return self
end

function BaseMenuManager:populate_menu_state(new_step: menu_types.MenuStep)
    self.menu_state.step = new_step

    local menu_data = self.menu_definitions[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]
    
    self.menu_step = new_step_data:build(self.game_ctx, self.menu_ctx, self.menu_state)
end

function BaseMenuManager:handle_menu_advance(next_state: string)
    pt.add(self.selection_history, {
        step = self.menu_state.step,
    })

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end
end

function BaseMenuManager:handle_menu_back()
    local previous_step = self.menu_definitions[self.menu_state.menu_id]
        .steps[self.menu_state.step]
        .previous_step

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
        -- self.menu_cursor = self.selection_history[#self.selection_history].selection
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
    
    if input is input_context.JoypadContext then
        btn_skip_turn = input.joypad.lp      
    elseif input is input_context.MouseContext then
    else
        unexpected(input.type)
    end

    if btn_skip_turn then
        -- DEBUG Only for now.  consider where to put
        self.event_writer:emit("TACTICS_FINISH_SIDE_ACTIONS", {})
        return
    end

    local signal = input_context.handle_update(
        input,
        function(joy: Joypad): MenuSignal
            return self.menu_step.node:update_joy(joy, self.game_ctx, self.menu_ctx)
        end,
        function(
            mouse: Mouse,
            hovered: mouse_menu_selection.MenuMouseSelection
        ): MenuSignal
            return self.menu_step.node:update_mouse(mouse, hovered, self.game_ctx, self.menu_ctx)
        end
    )

    if signal is menu_signal.Consumed then
        return
    elseif signal is menu_signal.Ignored then
        -- TODO: joy/mouse step-level back
        -- if joy.bp then

        -- end 
    elseif signal is menu_signal.Back then
        self:handle_menu_back()
    elseif signal is menu_signal.Navigate then
        self:handle_menu_advance(signal.target)
    else
        unexpected(signal.type)
    end
end

function BaseMenuManager:serialize(): SerializedMenu
    return {
        menu_id = self.menu_state.menu_id,
        step = self.menu_state.step,
        node = self.menu_step and self.menu_step.node:serialize()
    }
end

return menu_manager
