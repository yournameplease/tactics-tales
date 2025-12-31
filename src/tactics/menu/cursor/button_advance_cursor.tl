local menu_cursor = require("src/tactics/menu/menu_cursor")
local menu_types = require("src/tactics/menu/types")
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local Joypad = require("src/tactics/joypad").Joypad
local event_bus = require("src/tactics/systems/event_bus")

local record ButtonAdvanceCursor<GC>
    is menu_cursor.MenuCursor<GC>
    where self.type == "CURSOR_BUTTON_ADVANCE"

    -- from definition
    next_state: menu_types.MenuStep
    send_command: event_bus.GameEvent
end

local record ButtonAdvanceMenuDefinition<GC>
    is menu_cursor.MenuStepDefinition<GC>
    where self.type == "CURSOR_BUTTON_ADVANCE" 
    next_state: menu_types.MenuStep
    send_command: event_bus.GameEvent
end

local button_advance_cursor = {
    ButtonAdvanceCursor = ButtonAdvanceCursor,
    ButtonAdvanceMenuDefinition = ButtonAdvanceMenuDefinition,
}

function button_advance_cursor.definition<GC>(props: ButtonAdvanceMenuDefinition<GC>): ButtonAdvanceMenuDefinition<GC>
    props.type = "CURSOR_BUTTON_ADVANCE"
    return setmetatable(props, { __index = ButtonAdvanceMenuDefinition })
end

function ButtonAdvanceCursor:update(_joy: Joypad)
end

function ButtonAdvanceCursor:handle_select(_game_context: GC, _menu_ctx: MenuContext, _menu_state: menu_types.MenuState): string, event_bus.GameEvent
    return self.next_state, self.send_command
end

function ButtonAdvanceMenuDefinition:to_cursor(_game_context: GC, _menu_ctx: MenuContext, _menu_state: menu_types.MenuState): menu_cursor.MenuCursor<GC>
    local cursor: ButtonAdvanceCursor<GC> = {
        type = "CURSOR_BUTTON_ADVANCE",
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (ButtonAdvanceCursor as {string: any})[k] then
                return (ButtonAdvanceCursor as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

return button_advance_cursor
