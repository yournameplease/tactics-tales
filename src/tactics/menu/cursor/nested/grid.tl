---@brief
--- Implements a menu cursor for navigating a 2D grid, used for
--- selecting tiles on the battle map.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local MenuNode = menu_cursor.MenuNode
local point = require("src.tactics.util.point")
local Point = point.Point
local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_types = require("src.tactics.menu.types")
local input_service = require("src.tactics.joypad")
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local array_2d = require("src.tactics.util.array_2d")
local pathfinding = require("src.tactics.battle.pathfinding")

local record MenuTileHighlight
    reachable: boolean
    valid_selection: boolean
    can_attack: boolean
end

-- TODO: this is not ideal for memory.  ignoring for now though
local record NestedGridNode
    is menu_cursor.MenuContainer
    where self.type == "grid"
    point: Point
    x_max: integer
    y_max: integer
    path: { Point }
    legal_tiles: array_2d.Array2D<MenuTileHighlight>
    max_path_length: integer
    children: array_2d.Array2D<MenuNode>
end

local record NestedGridDefinition
    is menu_cursor.MenuContainerDefinition
    where self.type == "grid"

	get_child: function(point: Point): MenuNodeDefinition
    get_legal_tiles: function(GameContext, MenuContext): array_2d.Array2D<MenuTileHighlight>
    get_path_anchor: function(GameContext, MenuContext): Point
    get_max_path_length: function(GameContext, MenuContext): integer
end

local nested_grid = {
    MenuTileHighlight = MenuTileHighlight,
    NestedGridNode = NestedGridNode,
    NestedGridDefinition = NestedGridDefinition,
}

function nested_grid.definition(
    props: NestedGridDefinition
): NestedGridDefinition
    props.type = "grid"
    return setmetatable(props, { __index = NestedGridDefinition })
end

function NestedGridNode:update_joy(joy: Joypad)
    local prev_point = self.point:copy()
    self.point.x = pt.mid(0, self.point.x + joy.dxp, self.x_max - 1)
    self.point.y = pt.mid(0, self.point.y + joy.dyp, self.y_max - 1)

    if self.legal_tiles ~= nil and self.path ~= nil and self.point ~= prev_point then
        if self.legal_tiles:get_point(self.point) then
            
            local tiles = self.legal_tiles:map(function(h: MenuTileHighlight): boolean
                return h ~= nil and h.reachable
            end)
            self.path = pathfinding.extend_path_to_point(self.path, self.point, self.max_path_length, tiles)
        end
    end 
end

function NestedGridNode:update_mouse(
    _mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection
)
    if hovered == nil then return end

    if hovered is mouse_menu_selection.Grid then
        local prev_point = self.point:copy()
        self.point.x = pt.mid(0, hovered.x, self.x_max - 1)
        self.point.y = pt.mid(0, hovered.y, self.y_max - 1)

        if self.legal_tiles ~= nil and self.path ~= nil and self.point ~= prev_point then
            if self.legal_tiles:get_point(self.point) then
            
                local tiles = self.legal_tiles:map(function(h: MenuTileHighlight): boolean
                    return h ~= nil and h.reachable
                end)
                self.path = pathfinding.extend_path_to_point(self.path, self.point, self.max_path_length, tiles)
            end
        end
    end
end

function NestedGridDefinition:to_cursor(
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
): menu_cursor.MenuNode
    local cursor: NestedGridNode = {
        type = "grid",
        point = menu_state.point, 
        x_max = 16,
        y_max = 16
    }
    if self.get_legal_tiles ~= nil then
        cursor.legal_tiles = self.get_legal_tiles(game_ctx, menu_ctx)
        if self.get_max_path_length ~= nil then
            cursor.max_path_length = self.get_max_path_length(game_ctx, menu_ctx)
            if self.get_path_anchor then
                cursor.path = {self.get_path_anchor(game_ctx, menu_ctx)}
            else
                cursor.path = {menu_state.point:copy()}
            end
        else
            cursor.path = nil
            cursor.max_path_length = nil
        end
    else
        cursor.legal_tiles = nil
    end
    if self.get_child ~= nil then
		cursor.children = array_2d.new(cursor.x_max, cursor.y_max)
			:map_points(function(p: Point): MenuNode
				return self.get_child(p):to_cursor(game_ctx, menu_ctx, menu_state)
			end)
	end
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (NestedGridNode as {string: any})[k] then
                return (NestedGridNode as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

function nested_grid.grid(): NestedMenuDefinition
	return setmetatable({
	    get_children = get_children,
	    direction = "column",
	},{
	    __index = NestedMenuDefinition
	})
end

function NestedGridDefinition:with_children(
	get_child: function(point: Point): MenuNodeDefinition
): NestedGridDefinition
	self.get_child = get_child
end

function NestedGridDefinition:with_path_length(
	get_max_path_length: function(GameContext, MenuContext): Point
): NestedGridDefinition
	self.get_max_path_length = get_max_path_length
end

function NestedGridDefinition:with_path_anchor(
	get_path_anchor: function(GameContext, MenuContext): integer
): NestedGridDefinition
	self.get_path_anchor = get_path_anchor
end

return nested_grid

