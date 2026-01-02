local menu_cursor = require("src/tactics/menu/menu_cursor")
local menu_types = require("src/tactics/menu/types")
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local lists = require("src/tactics/util/lists")
local input_service = require("src/tactics/joypad")
local Joypad = require("src/tactics/joypad").Joypad
local Mouse = input_service.Mouse
local input_context = require("src/tactics/input/input_context")
local InputContext = input_context.InputContext
local mouse_menu_selection = require("src/tactics/menu/menu_cursor").mouse_selection
local event_bus = require("src/tactics/systems/event_bus")

global enum ListDirection
    "vertical"
    "horizontal"
end

-- Value is not needed if no context is stored...
-- I just use string for default
local record ListMenuOption<Value>
    text: string
    value: Value
    next_state: menu_types.MenuStep
    send_command: event_bus.GameEvent
end

local record ListMenuCursor<GC, Value>
    is menu_cursor.MenuCursor<GC>
    where self.type == "list"
    i: integer
    options: { ListMenuOption<Value> }

    -- from definition
    direction: ListDirection
    wrap: boolean
    set_selected_context: function(ListMenuCursor<GC, Value>, GC, MenuContext)
end

local record ListMenuDefinition<GC, Value>
    is menu_cursor.MenuStepDefinition<GC>
    where self.type == "list"
    set_selected_context: function(ListMenuCursor<GC, Value>, GC, MenuContext)
    get_options: function(GC, MenuContext): {ListMenuOption<Value>}
    wrap: boolean
    direction: ListDirection
end

local list_menu_cursor = {
    ListMenuOption = ListMenuOption,
    ListMenuCursor = ListMenuCursor,
    ListMenuDefinition = ListMenuDefinition,
}

function list_menu_cursor.definition<GC, Value>(props: ListMenuDefinition<GC, Value>): ListMenuDefinition<GC, Value>
    props.type = "list"
    props.direction = props.direction or "vertical"
    return setmetatable(props, { __index = ListMenuDefinition })
end

function list_menu_cursor.static_definition<GC, Value>(
    options: {Value},
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GC, Value>
    local get_options = function(_game_ctx: GC, _menu_context: MenuContext): {ListMenuOption}
        return lists.do_map(
            options,
            function (o: Value): ListMenuOption<Value>
                return {
                    text = tostring(o),
                    value = o
                }
            end
        )
    end
    local set_selected_context = function(s: ListMenuCursor<GC, Value>, _msb: GC, ctx: MenuContext)
        ctx.metadata[set_context_key] = options[s.i]
    end
    return list_menu_cursor.definition({
        set_selected_context = set_selected_context,
        get_options = get_options,
        wrap = false,
        direction = direction,
    })
end

function list_menu_cursor.integer_range<GC>(
    min_value: integer,
    max_value: integer,
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GC, integer>
    local options = {}
    for i=min_value,max_value do
        pt.add(options, i)
    end
    return list_menu_cursor.static_definition(
        options,
        set_context_key,
        direction
    )
end

function ListMenuCursor:update_joy(joy: Joypad)
    local new_i = self.i
    if self.direction == "vertical" then
        new_i = new_i + joy.dyp
    elseif self.direction == "horizontal" then
        new_i = new_i + joy.dxp
    else
        error()
    end

    if new_i ~= self.i then
        if self.wrap then
            self.i = (new_i - 1) % #self.options + 1
        else
            self.i = pt.mid(1, new_i, #self.options)
        end
    end
end

function ListMenuCursor:update_mouse(
    _mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection
)
    if hovered == nil then return end

    if hovered is mouse_menu_selection.List then
        if hovered.i > 0 and hovered.i <= #self.options then
            self.i = hovered.i
        end
    end
end

function ListMenuCursor:update(input: InputContext)
    if input is input_context.JoypadContext then
        self:update_joy(input.joypad)
    elseif input is input_context.MouseContext then
        self:update_mouse(input.mouse, input.hovered)
    else
        error()
    end
end

function ListMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, _: menu_types.MenuState): string, event_bus.GameEvent
    if self.set_selected_context ~= nil then
        self.set_selected_context(self, game_ctx, menu_ctx)
    end
    return self.options[self.i].next_state, self.options[self.i].send_command
end

function ListMenuDefinition:to_cursor(game_ctx: GC, menu_ctx: MenuContext, _: menu_types.MenuState): menu_cursor.MenuCursor<GC>
    local cursor: ListMenuCursor<GC, Value> = {
        type = "list",
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
