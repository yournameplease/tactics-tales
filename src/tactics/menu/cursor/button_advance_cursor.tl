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


function ButtonAdvanceCursor.new(step_definition: any, _: GC, _: MenuContext, _: MenuState): ButtonAdvanceCursor<GC>
    assert(step_definition is ButtonAdvanceMenuDefinition<GC>)
    local self: ButtonAdvanceCursor<GC> = {
        type = "CURSOR_BUTTON_ADVANCE",
    }
    return setmetatable(self, { __index = function(t: any, k: string): any 
            if (ButtonAdvanceCursor as {string: any})[k] then
                return (ButtonAdvanceCursor as {string: any})[k]
            end
            return (step_definition as {string: any})[k]
        end
        })
end

function ButtonAdvanceCursor:update(_joy: Joypad)
end

function ButtonAdvanceCursor:handle_select(game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    return self.next_state, self.send_command
end

function ButtonAdvanceMenuDefinition:to_cursor(game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
    return ButtonAdvanceCursor.new(self, game_context, menu_ctx, menu_state)
end
