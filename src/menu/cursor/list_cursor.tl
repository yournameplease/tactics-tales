require("src/menu/menu_cursor")
require("src/game_context")

global type MenuState
global type MenuContext

global enum ListDirection
    "vertical"
    "horizontal"
end

global record MenuOption
    text: string
    next_state: MenuStep
    send_command: GameEvent
end

global record ListMenuCursor<GC is GameContext>
    is MenuCursor<GC>
    where self.type == "CURSOR_LIST"
    i: integer
    options: { MenuOption }
    direction: ListDirection

    -- from definition
    wrap: boolean
    set_selected_context: function(ListMenuCursor<GC>, GC, MenuContext)
end

global record ListMenuDefinition<GC is GameContext>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_LIST"
    set_selected_context: function(ListMenuCursor<GC>, GC, MenuContext)
    get_options: function(GC, MenuContext): {MenuOption}
    wrap: boolean
end

function ListMenuDefinition.new(props: ListMenuDefinition<GC>): ListMenuDefinition<GC>
    props.type = "CURSOR_LIST"
    return props
end

function ListMenuCursor.new(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): ListMenuCursor<GC>
    assert(step_definition is ListMenuDefinition<GC>)
    local self: ListMenuCursor<GC> = {
        type = "CURSOR_LIST",
        i = 1,
        options = step_definition.get_options(game_ctx, menu_ctx),
        direction = "vertical",
    }
    return setmetatable(self, { __index = function(t: any, k: string): any 
            if (ListMenuCursor as {string: any})[k] then
                return (ListMenuCursor as {string: any})[k]
            end
            return (step_definition as {string: any})[k]
        end
        })
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

function ListMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    if self.set_selected_context ~= nil then
        self.set_selected_context(self, game_ctx, menu_ctx)
    end
    return self.options[self.i].next_state, self.options[self.i].send_command
end