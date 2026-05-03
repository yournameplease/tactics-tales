---@brief
--- A generic manager for menu systems. It handles state transitions,
--- history, and dispatches input to the active menu cursor.

local input_context = require("src.tactics.input.input_context")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal

---@class SelectionHistory
---@field step string MenuStep identifier recorded before navigating forward.

---@alias MenuHandlerPostHandlingType "consume"|"navigate"|"deserialize"|"move_cursor"|"recompute_menu"

---@class MenuHandlerPostHandling Abstract base for values returned by menu handlers.
---@field type MenuHandlerPostHandlingType

---@class MenuHandlerDeserialize : MenuHandlerPostHandling
---@field type "deserialize"
---@field data table<string, any> Data to deserialize into the active menu node.

---@class MenuHandlerMoveCursor : MenuHandlerPostHandling
---@field type "move_cursor"
---@field point Point Destination for the grid cursor.

---@class MenuHandlerRecompute : MenuHandlerPostHandling
---@field type "recompute_menu"

---@class MenuHandlerConsume : MenuHandlerPostHandling
---@field type "consume"

---@class MenuHandlerNavigate : MenuHandlerPostHandling
---@field type "navigate"
---@field next_step string Step to navigate to.

---@alias MenuHandler<TServices, TSession> fun(services: TServices, menu_data: table<string, any>, session_context: TSession, value: any): MenuHandlerPostHandling?

local menu_handler = {}

--- Return a handler result that deserializes data into the active node.
---@param data table<string, any>
---@return MenuHandlerDeserialize
function menu_handler.then_deserialize(data)
    return { type = "deserialize", data = data }
end

--- Return a handler result that triggers a full menu recompute.
---@return MenuHandlerRecompute
function menu_handler.then_recompute()
    return { type = "recompute_menu" }
end

--- Return a handler result that consumes the navigation signal without moving.
---@return MenuHandlerConsume
function menu_handler.then_dont_navigate()
    return { type = "consume" }
end

--- Return a handler result that navigates to the given step.
---@param next_step string
---@return MenuHandlerNavigate
function menu_handler.then_navigate(next_step)
    return { type = "navigate", next_step = next_step }
end

--- Return a handler result that moves the active grid cursor to a point.
---@param pt Point
---@return MenuHandlerMoveCursor
function menu_handler.then_move_cursor(pt)
    return { type = "move_cursor", point = pt }
end

---@class ActiveMenuStep Active state for a single menu step.
---@field previous_step? string Step to return to on back.
---@field handlers table<string, string>? Map from MenuCommand to MenuHandlerId.
---@field node MenuNode Active root node for this step.
---@field default_lmb? string Default command for left mouse button.
---@field default_rmb? string Default command for right mouse button.
---@field menu_actions? MenuActions Map from InputAction to MenuAction.
---@field keyboard_handler? string
---@field backspace_handler? string
local MenuStep = {}
MenuStep.__index = MenuStep

---@class MenuStepDefinition Build spec for a single menu step.
---@field previous_step? string
---@field handlers table<string, string>? Map from MenuCommand to MenuHandlerId.
---@field node MenuNodeDefinition Root node definition.
---@field default_lmb? string
---@field default_rmb? string
---@field initial_data (fun(game_ctx: GameContext, menu_ctx: MenuContext): table<string, any>)?
---@field menu_actions? MenuActions
---@field keyboard_handler? string MenuHandlerId called with concatenated text when peektext() is truthy. Returns true to also allow joypad this frame.
---@field backspace_handler? string MenuHandlerId called when keyp("backspace") is true.
local MenuStepDefinition = {}
MenuStepDefinition.__index = MenuStepDefinition

local menu_step_definition = {}

--- Create a MenuStepDefinition wrapping the given node definition.
---@param node_definition MenuNodeDefinition
---@return MenuStepDefinition
function menu_step_definition.of_node(node_definition)
    return setmetatable({ node = node_definition }, { __index = MenuStepDefinition })
end

--- Set the step to return to when navigating back.
---@param step_id string
---@return MenuStepDefinition
function MenuStepDefinition:with_previous_step(step_id)
    self.previous_step = step_id
    return self
end

--- Register a handler ID for a specific command on this step.
---@param command string MenuCommand value.
---@param handler string MenuHandlerId to invoke.
---@return MenuStepDefinition
function MenuStepDefinition:handle_action(command, handler)
    if self.handlers == nil then
        self.handlers = {}
    end
    self.handlers[command] = handler
    return self
end

--- Set a function that provides initial deserialization data when the step is entered.
---@param initial_data fun(game_ctx: GameContext, menu_ctx: MenuContext): table<string, any>
---@return MenuStepDefinition
function MenuStepDefinition:with_initial_data(initial_data)
    self.initial_data = initial_data
    return self
end

--- Bind an input action to a menu command on this step.
---@param input InputAction
---@param action MenuAction
---@return MenuStepDefinition
function MenuStepDefinition:with_action(input, action)
    if self.menu_actions == nil then
        self.menu_actions = {}
    end
    self.menu_actions[input] = action
    return self
end

--- Register a handler to receive real keyboard text input via peektext()/readtext().
---@param handler_id string MenuHandlerId to invoke with concatenated text. Returns true to allow joypad the same frame.
---@return MenuStepDefinition
function MenuStepDefinition:with_keyboard_handler(handler_id)
    self.keyboard_handler = handler_id
    return self
end

---@param handler_id string MenuHandlerId to invoke when keyp("backspace") is true.
---@return MenuStepDefinition
function MenuStepDefinition:with_backspace_handler(handler_id)
    self.backspace_handler = handler_id
    return self
end

--- Replace all input-action bindings for this step at once.
---@param menu_actions MenuActions
---@return MenuStepDefinition
function MenuStepDefinition:with_actions(menu_actions)
    self.menu_actions = menu_actions
    return self
end

--- Set the default command issued on left mouse button when no node is hovered.
---@param default_lmb string MenuCommand value.
---@return MenuStepDefinition
function MenuStepDefinition:with_default_lmb(default_lmb)
    self.default_lmb = default_lmb
    return self
end

--- Set the default command issued on right mouse button when no node is hovered.
---@param default_rmb string MenuCommand value.
---@return MenuStepDefinition
function MenuStepDefinition:with_default_rmb(default_rmb)
    self.default_rmb = default_rmb
    return self
end

--- Build the active MenuStep from this definition.
---@param game_ctx GameContext
---@param menu_ctx MenuContext
---@param menu_state MenuState
---@return ActiveMenuStep
function MenuStepDefinition:build(game_ctx, menu_ctx, menu_state)
    local out = {
        node = self.node:to_cursor(nil, game_ctx, menu_ctx, menu_state),
        handlers = self.handlers,
    }
    out.node:refresh_focus()
    ---@type ActiveMenuStep
    local step = setmetatable(out, { __index = function(_, k)
        if MenuStep[k] then
            return MenuStep[k]
        end
        return self[k]
    end })
    return step
end

---@class MenuDefinition
---@field initial_step string Starting step ID.
---@field steps table<string, MenuStepDefinition> All step definitions keyed by step ID.
---@field handlers table<string, MenuHandler> Handler map for this menu.

---@class MenuManagerSerializedMenu
---@field menu_id? string Active menu ID; nil when no menu is open.
---@field step? string Active step ID.
---@field node? SerializedMenu Serialized root node state.

---@class MenuManager Abstract interface for menu managers.
---@field menu_definitions table<string, MenuDefinition>
---@field menu_state MenuState
---@field menu_ctx? MenuContext
---@field menu_step? ActiveMenuStep Active step node and bindings; nil when no menu is open.
---@field selection_history SelectionHistory[]
---@field revision_count integer Incremented on every structural change; used by UI to detect dirty state.
---@field game_ctx GameContext
---@field event_writer EventWriter
local BaseMenuManager = {}
BaseMenuManager.__index = BaseMenuManager

local menu_manager = {
    MenuManager = BaseMenuManager,
    MenuHandler = {},       -- type alias placeholder
    menu_handler = menu_handler,
    SelectionHistory = {},  -- type alias placeholder
    MenuDefinition = {},    -- type alias placeholder
    MenuStepDefinition = MenuStepDefinition,
    MenuStep = MenuStep,

    definition = {
        step = menu_step_definition,
    },
}

--- Create a new MenuManager.
---@param menu_definitions table<string, MenuDefinition>
---@param ctx GameContext
---@param bus EventBus
---@return MenuManager
function menu_manager.new(menu_definitions, ctx, bus)
    ---@type MenuManager
    local self = setmetatable({}, { __index = BaseMenuManager })

    self.menu_definitions = menu_definitions

    ---@type MenuState
    self.menu_state = { step = nil, menu_id = nil }
    self.menu_ctx = { metadata = {} }
    self.selection_history = {}

    self.game_ctx = ctx
    self.event_writer = event_writer.new(bus)
    self.revision_count = 0

    return self
end

--- Transition to a new step within the current menu.
---@param new_step string Target step ID.
function BaseMenuManager:populate_menu_state(new_step)
    self.menu_state.step = new_step

    local menu_data = self.menu_definitions[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]

    self.menu_step = new_step_data:build(self.game_ctx, self.menu_ctx, self.menu_state)
    if new_step_data.initial_data then
        self.menu_step.node:deserialize(
            nil,
            new_step_data.initial_data(self.game_ctx, self.menu_ctx)
        )
    end

    self.revision_count = self.revision_count + 1
end

--- Record the current step in history and advance to next_state.
---@param next_state string? Target step ID; nil is a no-op navigation.
function BaseMenuManager:handle_menu_advance(next_state)
    table.insert(self.selection_history, { step = self.menu_state.step })

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end
end

--- Navigate back, optionally all the way to a named step, firing back handlers along the way.
---@param target_step? string If provided, keep backing up until this step is reached.
function BaseMenuManager:handle_menu_back(target_step)
    local menu_def = self.menu_definitions[self.menu_state.menu_id]
    local previous_step = menu_def.steps[self.menu_state.step].previous_step

    if previous_step == nil then
        return
    end

    if target_step == nil then
        log.debug("Backing out of " .. self.menu_state.menu_id .. " to " .. previous_step)
        while #self.selection_history > 0 and
            self.selection_history[#self.selection_history].step ~= previous_step do
            self.selection_history[#self.selection_history] = nil
        end
        if #self.selection_history > 0 then
            self.selection_history[#self.selection_history] = nil
        end
        self:populate_menu_state(previous_step)
        return
    end

    -- Verify target_step is reachable by following the previous_step chain.
    local reachable = false
    local check = previous_step
    while check ~= nil do
        if check == target_step then
            reachable = true
            break
        end
        check = menu_def.steps[check] and menu_def.steps[check].previous_step
    end
    assert(reachable, "target_step '" .. target_step .. "' is not reachable from '" .. self.menu_state.step .. "'")

    log.debug("Backing out of " .. self.menu_state.menu_id .. " to " .. target_step)

    -- Walk the previous_step chain, firing each intermediate step's back handler.
    local current = previous_step
    while current ~= target_step do
        local step_def = menu_def.steps[current]
        local handler_id = step_def.handlers and step_def.handlers["back"]
        if handler_id then
            local handler = self.menu_definitions[self.menu_state.menu_id].handlers[handler_id]
            assert(handler ~= nil, "Bad handler for id " .. handler_id)
            log.debug("Calling back handler for intermediate step: " .. current)
            handler(self.game_ctx, self:serialize().node.data, self.menu_ctx, nil)
        end
        current = step_def.previous_step
    end

    while #self.selection_history > 0 and
        self.selection_history[#self.selection_history].step ~= target_step do
        self.selection_history[#self.selection_history] = nil
    end
    if #self.selection_history > 0 then
        self.selection_history[#self.selection_history] = nil
    end
    self:populate_menu_state(target_step)
end

--- Close the active menu and reset all state.
function BaseMenuManager:clear_menu()
    log.debug("Clearing menu. Was ", self.menu_state.menu_id)
    self.menu_state.menu_id = nil
    self.menu_ctx = nil
    self.menu_step = nil
    self.selection_history = {}
    self.revision_count = self.revision_count + 1
end

--- Open a menu by ID, initialising its first step.
---@param menu_id string
function BaseMenuManager:set_menu(menu_id)
    log.debug("Setting menu: " .. menu_id)
    local definition = self.menu_definitions[menu_id]
    self.menu_state.menu_id = menu_id
    self.menu_ctx = { metadata = {} }
    self.selection_history = {}
    local step = definition.initial_step
    self:populate_menu_state(step)
end

--- Process one frame of input, dispatching to the active step and handling signals.
---@param input InputContext
function BaseMenuManager:update(input)
    if self.menu_step ~= nil then
        local allow_joypad = true
        if peektext() then
            if self.menu_step.keyboard_handler then
                local text = ""
                while peektext() do
                    text = text .. readtext()
                end
                local menu_data = self:serialize().node.data
                local focused = self.menu_step.node:get_focused_leaves(self.menu_ctx, self.game_ctx)
                for _, leaf in ipairs(focused) do
                    if leaf.keyboard_handler then
                        local leaf_handler = self.menu_definitions[self.menu_state.menu_id].handlers[leaf.keyboard_handler]
                        if leaf_handler then
                            leaf_handler(self.game_ctx, menu_data, self.menu_ctx, text)
                        end
                    end
                end
                local step_handler = self.menu_definitions[self.menu_state.menu_id].handlers[self.menu_step.keyboard_handler]
                assert(step_handler ~= nil, "Bad handler for id " .. self.menu_step.keyboard_handler)
                allow_joypad = step_handler(self.game_ctx, menu_data, self.menu_ctx) == true
            else
                -- prevent buildup of text buffer if no keyboard handler
                -- two "z" will still come through, though...
                readtext(true)
            end
        end

        if self.menu_step.backspace_handler and keyp("backspace") then
            local menu_data = self:serialize().node.data
            local bs_handler = self.menu_definitions[self.menu_state.menu_id].handlers[self.menu_step.backspace_handler]
            assert(bs_handler ~= nil, "Bad handler for id " .. self.menu_step.backspace_handler)
            bs_handler(self.game_ctx, menu_data, self.menu_ctx)
        end

        if not allow_joypad then return end

        local signal = input_context.handle_update(
            input,
            function(joy)
                local button_priority = {
                    "BUTTON_A",
                    "BUTTON_B",
                    "SHOULDER_L",
                    "SHOULDER_R",
                }
                local commands = {}

                if self.menu_step.menu_actions then
                    for _, btn in ipairs(button_priority) do
                        if self.menu_step.menu_actions[btn] and input.actions[btn].pressed then
                            table.insert(commands, self.menu_step.menu_actions[btn].command)
                        end
                    end
                end

                return self.menu_step.node:update_joy(joy, commands, self.menu_ctx, self.game_ctx)
            end,
            function(mouse, hovered)
                if hovered == nil then hovered = {} end

                if hovered.node then
                    hovered.node:claim_focus(hovered, nil)
                end

                local sig = menu_signal.ignored()
                if hovered.node then
                    sig = hovered.node:update_mouse(mouse, hovered, self.menu_ctx, self.game_ctx)
                end

                if sig.type ~= "ignored" then return sig end

                local command
                if (hovered.on_lmb_command or self.menu_step.default_lmb) and mouse.mlp then
                    if hovered.on_lmb_command then
                        command = hovered.on_lmb_command
                    else
                        command = self.menu_step.default_lmb
                        hovered.node = self.menu_step.node
                    end
                elseif (hovered.on_rmb_command or self.menu_step.default_rmb) and mouse.mrp then
                    if hovered.on_rmb_command then
                        command = hovered.on_rmb_command
                    else
                        command = self.menu_step.default_rmb
                        hovered.node = self.menu_step.node
                    end
                end
                if command then
                    log.debug("Got mouse command: " .. command .. " for " .. hovered.node.id)
                    return hovered.node:handle_command(command, self.menu_ctx, self.game_ctx)
                end
                return menu_signal.ignored()
            end
        )

        if signal.type == "consumed" then
            return
        elseif signal.type == "ignored" then
            local triggered_command
            if self.menu_step.menu_actions then
                for input_name, state in pairs(input.actions) do
                    if state.pressed then
                        local action = self.menu_step.menu_actions[input_name]
                        if action then
                            triggered_command = action.command
                            break
                        end
                    end
                end
            end

            if triggered_command == nil then
                -- fallback for mouse: right-click always means back
                if input.type == "mouse" then
                    ---@cast input MouseContext
                    if input.mouse.mrp then
                        triggered_command = "back"
                    end
                end
            end

            if triggered_command then
                local handler_id = self.menu_step.handlers and self.menu_step.handlers[triggered_command]
                if handler_id then
                    local handler = self.menu_definitions[self.menu_state.menu_id].handlers[handler_id]
                    assert(handler ~= nil, "Bad handler for id " .. handler_id)
                    log.debug("Calling menu handler: " .. handler_id)
                    handler(
                        self.game_ctx,
                        self:serialize().node.data,
                        self.menu_ctx,
                        nil
                    )
                end
                if triggered_command == "back" then
                    self:handle_menu_back()
                end
            end
        elseif signal.type == "back" then
            ---@cast signal MenuSignalBack
            local handler_id = self.menu_step.handlers and self.menu_step.handlers["back"]
            if handler_id then
                local handler = self.menu_definitions[self.menu_state.menu_id].handlers[handler_id]
                assert(handler ~= nil, "Bad handler for id " .. handler_id)
                log.debug("Calling menu handler: " .. handler_id)
                handler(
                    self.game_ctx,
                    self:serialize().node.data,
                    self.menu_ctx,
                    nil
                )
            end
            self:handle_menu_back(signal.target)
        elseif signal.type == "navigate" then
            ---@cast signal MenuSignalNavigate
            self:handle_menu_advance(signal.target)
        elseif signal.type == "on_change" then
            ---@cast signal MenuSignalOnChange
            local handler = self.menu_definitions[self.menu_state.menu_id].handlers[signal.handler]
            assert(handler ~= nil, "Bad handler for id " .. signal.handler)
            local handler_res = handler(
                self.game_ctx,
                self:serialize().node.data,
                self.menu_ctx,
                signal.value
            )
            if handler_res and handler_res.type == "deserialize" then
                ---@cast handler_res MenuHandlerDeserialize
                self.menu_step.node:deserialize(nil, handler_res.data)
            end
        elseif signal.type == "finish" then
            self:clear_menu()
        elseif signal.type == "call_handler" then
            ---@cast signal MenuSignalCallHandler
            local handler = self.menu_definitions[self.menu_state.menu_id].handlers[signal.handler]
            assert(handler ~= nil, "Bad handler for id " .. signal.handler)
            log.debug("Calling menu handler: " .. signal.handler)
            local ser = self:serialize()
            log.debug(ser.menu_id)
            log.debug(ser.step)
            log.debug(ser.node)
            local handler_res = handler(
                self.game_ctx,
                self:serialize().node.data,
                self.menu_ctx,
                signal.value
            )
            if handler_res then
                if handler_res.type == "navigate" then
                    ---@cast handler_res MenuHandlerNavigate
                    log.debug("Navigating from menu handler response.", self.menu_state.step)
                    signal.then_navigate_to = nil
                    self:handle_menu_advance(handler_res.next_step)
                elseif handler_res.type == "deserialize" then
                    ---@cast handler_res MenuHandlerDeserialize
                    log.debug("Deserializing from menu handler response.", self.menu_state.step)
                    self.menu_step.node:deserialize(nil, handler_res.data)
                elseif handler_res.type == "move_cursor" then
                    ---@cast handler_res MenuHandlerMoveCursor
                    log.debug("Moving cursor from menu handler response.", self.menu_state.step)
                    if handler_res.point then
                        ---@type SerializedNestedGridState
                        local state = {
                            type = "grid",
                            point = handler_res.point,
                            children = {},
                        }
                        self.menu_step.node:deserialize(state, {})
                    else
                        todo("Movement handler not implemented outside of grids")
                    end
                elseif handler_res.type == "recompute_menu" then
                    log.debug("Recomputing from menu handler response.", self.menu_state.step)
                    self.menu_step.node:recompute(self.game_ctx, self.menu_ctx)
                end
            end
            if signal.then_finish then
                self:clear_menu()
            end
            if signal.then_navigate_to ~= nil then
                if not (handler_res and handler_res.type == "consume") then
                    self:handle_menu_advance(signal.then_navigate_to)
                end
            end
            if signal.then_back or signal.then_back_to then
                local handler_id = self.menu_step.handlers and self.menu_step.handlers["back"]
                if handler_id then
                    local back_handler = self.menu_definitions[self.menu_state.menu_id].handlers[handler_id]
                    assert(back_handler ~= nil, "Bad handler for id " .. handler_id)
                    log.debug("Calling menu handler: " .. handler_id)
                    back_handler(
                        self.game_ctx,
                        self:serialize().node.data,
                        self.menu_ctx,
                        nil
                    )
                end
                self:handle_menu_back(signal.then_back_to)
            end
        else
            error("unexpected signal type: " .. tostring(signal.type))
        end
    end
end

--- Serialize the current menu state (active menu, step, and node tree).
---@return MenuManagerSerializedMenu
function BaseMenuManager:serialize()
    return {
        menu_id = self.menu_state.menu_id,
        step = self.menu_state.step,
        node = self.menu_step and self.menu_step.node:serialize()
    }
end

return menu_manager
