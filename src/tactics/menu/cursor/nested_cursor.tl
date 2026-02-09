
---@brief
--- Implements a menu cursor for navigating a 1D list of options,
--- supporting both horizontal and vertical lists.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local MenuNode = menu_cursor.MenuNode
local menu_types = require("src.tactics.menu.types")
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local lists = require("src.tactics.util.lists")
local input_service = require("src.tactics.joypad")
local Joypad = require("src.tactics.joypad").Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local enum NestedMenuType
    "row"
    "column"
    "grid"
end

local record NestedMenuNode
    is menu_cursor.MenuNode
    where self.type == "nested"
    i: integer
    children: { menu_cursor.MenuNode }

    -- from definition
    direction: NestedMenuType
    wrap: boolean
end

local record NestedMenuDefinition
    is menu_cursor.MenuNodeDefinition
    where self.type == "nested"
    get_children: function(GameContext, MenuContext): {menu_cursor.MenuNodeDefinition}
    wrap: boolean
    direction: NestedMenuType
end

local nested_menu = {
    NestedMenuNode = NestedMenuNode,
    NestedMenuDefinition = NestedMenuDefinition,
}

function nested_menu.definition(props: NestedMenuDefinition): NestedMenuDefinition
    props.type = "nested"
    props.direction = props.direction or "column"
    return setmetatable(props, { __index = NestedMenuDefinition })
end

function NestedMenuNode:update_joy(joy: Joypad)
    local new_i = self.i
    if self.direction == "column" then
        new_i = new_i + joy.dyp
    elseif self.direction == "row" then
        new_i = new_i + joy.dxp
    else
        unexpected(self.direction)
    end

    if new_i ~= self.i then
        if self.wrap then
            self.i = (new_i - 1) % #self.children + 1
        else
            self.i = pt.mid(1, new_i, #self.children)
        end
    end
end

function NestedMenuNode:update_mouse(
    _mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection
)
    if hovered == nil then return end

    if hovered is mouse_menu_selection.List then
        if hovered.i > 0 and hovered.i <= #self.children then
            self.i = hovered.i
        end
    end
end

function NestedMenuDefinition:to_cursor(game_ctx: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): menu_cursor.MenuNode
    local cursor: NestedMenuNode = {
        type = "nested",
        i = 1,
        children = lists.map(function(def: MenuNodeDefinition): MenuNode
            return def:to_cursor(game_ctx, menu_ctx, menu_state)
        end)(self.get_children(game_ctx, menu_ctx)),
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (NestedMenuNode as {string: any})[k] then
                return (NestedMenuNode as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

--- builders

function nested_menu.column(
	get_children: function(game_ctx: GameContext, menu_ctx: MenuContext): {MenuNodeDefinition}
): NestedMenuDefinition
	return setmetatable({
	    get_children = get_children,
	    direction = "column",
	},{
	    __index = NestedMenuDefinition
	})
end

return nested_menu
