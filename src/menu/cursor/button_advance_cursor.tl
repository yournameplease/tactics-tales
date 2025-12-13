require("src/menu/menu_cursor")
require("src/game_context")

global type MenuState
global type MenuContext

global record ButtonAdvanceCursor<GC is GameContext>
    is MenuCursor<GC>
    where self.type == "CURSOR_BUTTON_ADVANCE"

    -- from definition
    next_state: MenuStep
    send_command: GameEvent
end

global record ButtonAdvanceMenuDefinition<GC is GameContext>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_BUTTON_ADVANCE" 
    next_state: MenuStep
    send_command: GameEvent
end

function ButtonAdvanceMenuDefinition.new(props: ButtonAdvanceMenuDefinition<GC>): ButtonAdvanceMenuDefinition<GC>
    props.type = "CURSOR_BUTTON_ADVANCE"
    return props
end


function ButtonAdvanceCursor.new(step_definition: any, game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): ButtonAdvanceCursor<GC>
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