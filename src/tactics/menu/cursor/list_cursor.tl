require("src/tactics/menu/menu_cursor")
local lists = require("src/tactics/util/lists")
local Joypad = require("src/tactics/joypad").Joypad

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

global record ListMenuCursor<GC>
    is MenuCursor<GC>
    where self.type == "CURSOR_LIST"
    i: integer
    options: { MenuOption }

    -- from definition
    direction: ListDirection
    wrap: boolean
    set_selected_context: function(ListMenuCursor<GC>, GC, MenuContext)
end

global record ListMenuDefinition<GC>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_LIST"
    set_selected_context: function(ListMenuCursor<GC>, GC, MenuContext)
    get_options: function(GC, MenuContext): {MenuOption}
    wrap: boolean
    direction: ListDirection
end

function ListMenuDefinition.new(props: ListMenuDefinition<GC>): ListMenuDefinition<GC>
    props.type = "CURSOR_LIST"
    props.direction = props.direction or "vertical"
    return setmetatable(props, { __index = ListMenuDefinition })
end

function ListMenuDefinition.of_static_options<T>(
    options: {T},
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GC>
    local get_options = function(game_ctx: GC, menu_context: MenuContext): {MenuOption}
        return lists.do_map(
            options,
            function (o: T): MenuOption
                return {
                    text = tostring(o)
                }
            end
        )
    end
    local set_selected_context = function(s: ListMenuCursor<GC>, _msb: GC, ctx: MenuContext)
        ctx.metadata[set_context_key] = options[s.i]
    end
    return ListMenuDefinition.new({
        set_selected_context = set_selected_context,
        get_options = get_options,
        wrap = false,
        direction = direction,
    })
end

function ListMenuCursor.new(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): ListMenuCursor<GC>
    assert(step_definition is ListMenuDefinition<GC>)
    local self: ListMenuCursor<GC> = {
        type = "CURSOR_LIST",
        i = 1,
        options = step_definition.get_options(game_ctx, menu_ctx),
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
        self.i = pt.mid(1, new_i, #self.options)
    end
end

function ListMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    if self.set_selected_context ~= nil then
        self.set_selected_context(self, game_ctx, menu_ctx)
    end
    return self.options[self.i].next_state, self.options[self.i].send_command
end

function ListMenuDefinition:to_cursor(game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
    return ListMenuCursor.new(self, game_context, menu_ctx, menu_state)
end
