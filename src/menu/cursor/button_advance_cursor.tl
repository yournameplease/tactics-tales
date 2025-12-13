require("src/menu/menu_cursor")
require("src/game_context")

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
