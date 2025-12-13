require("src/menu/menu_cursor")
require("src/game_context")

global enum ListDirection
    "vertical"
    "horizontal"
end

global record MenuOption
    text: string
    next_state: MenuStep
    send_command: GameEvent
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