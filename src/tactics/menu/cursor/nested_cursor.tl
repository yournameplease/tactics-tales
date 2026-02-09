
---@brief
--- Implements a menu cursor for navigating a 1D list of options,
--- supporting both horizontal and vertical lists.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_types = require("src.tactics.menu.types")
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local lists = require("src.tactics.util.lists")
local input_service = require("src.tactics.joypad")
local Joypad = require("src.tactics.joypad").Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local record NestedMenuCursor
    is menu_cursor.MenuCursor
    where self.type == "nested"
    i: integer
    children: { menu_cursor.MenuCursor }

    -- from definition
    direction: MenuDirection
    wrap: boolean
end

local record NestedMenuDefinition<Value>
    is menu_cursor.MenuStepDefinition
    where self.type == "nested"
    get_children: function(GameContext, MenuContext): {menu_cursor.MenuStepDefinition}
    wrap: boolean
    direction: MenuDirection
end

local nested_menu = {
    NestedMenuCursor = NestedMenuCursor,
    NestedMenuDefinition = NestedMenuDefinition,
}

function nested_menu.definition<Value>(props: NestedMenuDefinition<Value>): NestedMenuDefinition<Value>
    props.type = "nested"
    props.direction = props.direction or "vertical"
    return setmetatable(props, { __index = NestedMenuDefinition })
end

function NestedMenuCursor:update_joy(joy: Joypad)
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

function NestedMenuCursor:update_mouse(
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

function NestedMenuDefinition:to_cursor(game_ctx: GameContext, menu_ctx: MenuContext, _: menu_types.MenuState): menu_cursor.MenuCursor
    local cursor: NestedMenuCursor<Value> = {
        type = "nested",
        i = 1,
        options = self.get_options(game_ctx, menu_ctx),
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (NestedMenuCursor as {string: any})[k] then
                return (NestedMenuCursor as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

--- builders

function nested_menu.column(
	get_children: function(game_ctx: GameContext, menu_ctx: MenuContext): MenuCursorDefinition
): NestedMenuDefinition
	
end

return nested_menu
