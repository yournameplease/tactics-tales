require("src/tactics/menu/menu_cursor")
require("src/tactics/menu/types")
local Joypad = require("src/tactics/joypad").Joypad

global record ButtonAdvanceCursor<GC>
    is MenuCursor<GC>
    where self.type == "CURSOR_BUTTON_ADVANCE"

    -- from definition
    next_state: MenuStep
    send_command: GameEvent
end

global record ButtonAdvanceMenuDefinition<GC>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_BUTTON_ADVANCE" 
    next_state: MenuStep
    send_command: GameEvent
end

function ButtonAdvanceMenuDefinition.new(props: ButtonAdvanceMenuDefinition<GC>): ButtonAdvanceMenuDefinition<GC>
    props.type = "CURSOR_BUTTON_ADVANCE"
    return setmetatable(props, { __index = ButtonAdvanceMenuDefinition })
end

function ButtonAdvanceCursor:update(_joy: Joypad)
end

function ButtonAdvanceCursor:handle_select(_game_context: GC, _menu_ctx: MenuContext, _menu_state: MenuState): string, GameEvent
    return self.next_state, self.send_command
end

function ButtonAdvanceMenuDefinition:to_cursor(_game_context: GC, _menu_ctx: MenuContext, _menu_state: MenuState): MenuCursor<GC>
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
