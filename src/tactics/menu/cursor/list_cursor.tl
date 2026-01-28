local menu_cursor = require("src/tactics/menu/menu_cursor")
local menu_types = require("src/tactics/menu/types")
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local lists = require("src/tactics/util/lists")
local input_service = require("src/tactics/joypad")
local Joypad = require("src/tactics/joypad").Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src/tactics/menu/menu_cursor").mouse_selection
local event_bus = require("src/tactics/systems/event_bus")

global enum ListDirection
    "vertical"
    "horizontal"
end

-- Value is not needed if no context is stored...
-- I just use string for default
local record ListMenuOption<GameContext, Value>
    text: string
    value: Value
    next_state: menu_types.MenuStep
    select_handler: function(self, GameContext, MenuContext)
    set_selected_context: function(GameContext, MenuContext)
end

local record ListMenuCursor<GameContext, Value>
    is menu_cursor.MenuCursor<GameContext>
    where self.type == "list"
    i: integer
    options: { ListMenuOption<GameContext, Value> }

    -- from definition
    direction: ListDirection
    wrap: boolean
    set_selected_context: function(ListMenuCursor<GameContext, Value>, GameContext, MenuContext)
    select_handler: function(self, GameContext, MenuContext)
    back_handler: function(self, GameContext, MenuContext)
end

local record ListMenuDefinition<GameContext, Value>
    is menu_cursor.MenuStepDefinition<GameContext>
    where self.type == "list"
    set_selected_context: function(ListMenuCursor<GameContext, Value>, GameContext, MenuContext)
    get_options: function(GameContext, MenuContext): {ListMenuOption<Value>}
    wrap: boolean
    direction: ListDirection
    select_handler: function(self, GameContext, MenuContext)
    back_handler: function(self, GameContext, MenuContext)
end

local list_menu_cursor = {
    ListMenuOption = ListMenuOption,
    ListMenuCursor = ListMenuCursor,
    ListMenuDefinition = ListMenuDefinition,
}

function list_menu_cursor.definition<GameContext, Value>(props: ListMenuDefinition<GameContext, Value>): ListMenuDefinition<GameContext, Value>
    props.type = "list"
    props.direction = props.direction or "vertical"
    return setmetatable(props, { __index = ListMenuDefinition })
end

function list_menu_cursor.static_definition<GameContext, Value>(
    options: {Value},
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GameContext, Value>
    local get_options = function(_game_ctx: GameContext, _menu_context: MenuContext): {ListMenuOption}
        return lists.do_map(
            options,
            function (o: Value): ListMenuOption<GameContext, Value>
                return {
                    text = tostring(o),
                    value = o
                }
            end
        )
    end
    local set_selected_context = function(s: ListMenuCursor<GameContext, Value>, _msb: GameContext, ctx: MenuContext)
        ctx.metadata[set_context_key] = options[s.i]
    end
    return list_menu_cursor.definition({
        set_selected_context = set_selected_context,
        get_options = get_options,
        wrap = false,
        direction = direction,
    })
end

function list_menu_cursor.boolean_yes_no<GameContext>(
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GameContext, boolean>
    local options: {boolean} = {false, true}
    
    local get_options = function(_game_ctx: GameContext, _menu_context: MenuContext): {ListMenuOption}
        return lists.do_map(
            options,
            function (o: boolean): ListMenuOption<GameContext, boolean>
                return {
                    text = o and "YES" or "NO",
                    value = o
                }
            end
        )
    end
    local set_selected_context = function(s: ListMenuCursor<GameContext, boolean>, _msb: GameContext, ctx: MenuContext)
        ctx.metadata[set_context_key] = options[s.i]
    end
    return list_menu_cursor.definition({
        set_selected_context = set_selected_context,
        get_options = get_options,
        wrap = false,
        direction = direction,
    })
end

function list_menu_cursor.integer_range<GameContext>(
    min_value: integer,
    max_value: integer,
    set_context_key: string,
    direction: ListDirection
): ListMenuDefinition<GameContext, integer>
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
        unexpected(self.direction)
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

function ListMenuCursor:handle_select(
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    _: menu_types.MenuState
): string
    if self.set_selected_context ~= nil then
        self:set_selected_context(game_ctx, menu_ctx)
    end
    if self.options[self.i].set_selected_context ~= nil then
        self.options[self.i].set_selected_context(game_ctx, menu_ctx)
    end
    if self.options[self.i].select_handler then
        self.options[self.i]:select_handler(game_ctx, menu_ctx)
    end
    if self.select_handler then
        self:select_handler(game_ctx, menu_ctx)
    end
    return self.options[self.i].next_state
end

function ListMenuCursor:handle_back(
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
) 
    if self.back_handler then
        self:back_handler(game_ctx, menu_ctx)
    end
end

function ListMenuDefinition:to_cursor(game_ctx: GameContext, menu_ctx: MenuContext, _: menu_types.MenuState): menu_cursor.MenuCursor<GameContext>
    local cursor: ListMenuCursor<GameContext, Value> = {
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
