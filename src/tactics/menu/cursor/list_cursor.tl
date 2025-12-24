local menu_cursor = require("src/tactics/menu/menu_cursor")
require("src/tactics/menu/types")
local lists = require("src/tactics/util/lists")
local Joypad = require("src/tactics/joypad").Joypad

global enum ListDirection
    "vertical"
    "horizontal"
end

local record ListMenuOption
    text: string
    next_state: MenuStep
    send_command: GameEvent
end

local record ListMenuCursor<GC>
    is menu_cursor.MenuCursor<GC>
    where self.type == "CURSOR_LIST"
    i: integer
    options: { ListMenuOption }

    -- from definition
    direction: ListDirection
    wrap: boolean
    set_selected_context: function(ListMenuCursor<GC>, GC, MenuContext)
end

local record ListMenuDefinition<GC>
    is menu_cursor.MenuStepDefinition<GC>
    where self.type == "CURSOR_LIST"
    set_selected_context: function(ListMenuCursor<GC>, GC, MenuContext)
    get_options: function(GC, MenuContext): {ListMenuOption}
    wrap: boolean
    direction: ListDirection
end

local list_menu_cursor = {
    ListMenuOption = ListMenuOption,
    ListMenuCursor = ListMenuCursor,
    ListMenuDefinition = ListMenuDefinition,
}

function list_menu_cursor.definition<GC>(props: ListMenuDefinition<GC>): ListMenuDefinition<GC>
    props.type = "CURSOR_LIST"
    props.direction = props.direction or "vertical"
    return setmetatable(props, { __index = ListMenuDefinition })
end

function list_menu_cursor.static_definition<T, GC>(
    options: {T},
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GC>
    local get_options = function(_game_ctx: GC, _menu_context: MenuContext): {ListMenuOption}
        return lists.do_map(
            options,
            function (o: T): ListMenuOption
                return {
                    text = tostring(o)
                }
            end
        )
    end
    local set_selected_context = function(s: ListMenuCursor<GC>, _msb: GC, ctx: MenuContext)
        ctx.metadata[set_context_key] = options[s.i]
    end
    return list_menu_cursor.definition({
        set_selected_context = set_selected_context,
        get_options = get_options,
        wrap = false,
        direction = direction,
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

function ListMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, _: MenuState): string, GameEvent
    if self.set_selected_context ~= nil then
        self.set_selected_context(self, game_ctx, menu_ctx)
    end
    return self.options[self.i].next_state, self.options[self.i].send_command
end

function ListMenuDefinition:to_cursor(game_ctx: GC, menu_ctx: MenuContext, _: MenuState): menu_cursor.MenuCursor<GC>
    local cursor: ListMenuCursor<GC> = {
        type = "CURSOR_LIST",
        i = 1,
        options = self.get_options(game_ctx, menu_ctx),
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (ListMenuCursor as {string: any})[k] then
                return (ListMenuCursor as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

return list_menu_cursor
