---@brief
--- Implements a menu cursor for navigating a 2D grid, used for
--- selecting tiles on the battle map.

local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local MenuSignal = menu_signal.MenuSignal
local SerializedMenu = menu_cursor.SerializedMenu
local SerializedMenuState = menu_cursor.SerializedMenuState
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local MenuNode = menu_cursor.MenuNode
local point = require("src.tactics.util.point")
local Point = point.Point
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
local button = require("src.tactics.menu.cursor.button")
local ButtonCursor = button.ButtonCursor

local record MenuTileHighlight
    reachable: boolean
    valid_selection: boolean
    can_attack: boolean
end

-- to be passed to button children
local record NestedGridValue
    point: Point
    path: { Point }
end

local record NestedGridChild
	filter: function(Point, GameContext, MenuContext): boolean
	child: MenuNode
end

local record NestedGridNode
    is menu_cursor.MenuContainer
    where self.type == "grid"
    point: Point
    x_max: integer
    y_max: integer
    path: { Point }
    legal_tiles: array_2d.Array2D<MenuTileHighlight>
    max_path_length: integer
    children: {NestedGridChild}
    child_array: array_2d.Array2D<MenuNode>
end

local record NestedGridChildDefinition
	filter: function(Point, GameContext, MenuContext): boolean
	child: MenuNodeDefinition
end

function NestedGridChildDefinition:to_cursor(
	parent: NestedGridNode,
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
): NestedGridChild
	return setmetatable({
		child = self.child:to_cursor(parent, game_ctx, menu_ctx, menu_state)	
	},{
		__index = self
	})
end

local record NestedGridDefinition
    is menu_cursor.MenuContainerDefinition
    where self.type == "grid"

    children: {NestedGridChildDefinition}
    get_legal_tiles: function(GameContext, MenuContext): array_2d.Array2D<MenuTileHighlight>
    get_path_anchor: function(GameContext, MenuContext): Point
    get_max_path_length: function(GameContext, MenuContext): integer
end

local record SerializedNestedGridState
	is SerializedMenuState
	where self.type == "grid"
	point: Point
	path: {Point}
	tile_highlights: array_2d.Array2D<MenuTileHighlight>
end

local nested_grid = {
    MenuTileHighlight = MenuTileHighlight,
    NestedGridNode = NestedGridNode,
    NestedGridDefinition = NestedGridDefinition,
    SerializedNestedGridState = SerializedNestedGridState,
	NestedGridValue = NestedGridValue,
}

function nested_grid.definition(
    props: NestedGridDefinition
): NestedGridDefinition
    props.type = "grid"
    return setmetatable(props, { __index = NestedGridDefinition })
end

function NestedGridNode:get_first_child(p: Point, game_context: GameContext, menu_ctx: MenuContext): menu_cursor.MenuNode
	for _,child in ipairs(self.children) do
		if child.filter(p, game_context, menu_ctx) then
			log.debug("Got child "..child.child.id.." for "..tostring(p))
			return child.child
		end
	end
end

function NestedGridNode:get_focused_leaf(): menu_cursor.MenuLeaf
	local child = self.child_array:get_point(self.point)
	if child is menu_cursor.MenuLeaf then
		return child
	elseif child is menu_cursor.MenuContainer then
		return child:get_focused_leaf()
	end
end

function NestedGridNode:get_nested_grid_value(): NestedGridValue
	return {
		point = self.point,
		path = self.path
	}
end

function NestedGridNode:update_joy(
	joy: Joypad
): MenuSignal
	local focused_leaf = self:get_focused_leaf()

	local signal = menu_signal.ignored()
	if focused_leaf ~= nil then
		if focused_leaf is ButtonCursor then
			focused_leaf.value = self:get_nested_grid_value()
		end
		signal = focused_leaf:update_joy(joy)
	end

    if signal.type ~= "ignored" then return signal end
    
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
        return menu_signal.consumed()
    end

    return menu_signal.ignored()
end

function NestedGridNode:claim_focus(
    selection: mouse_menu_selection.MenuMouseSelection,
    _child: menu_cursor.MenuNode
)
	if selection ~= nil then
		if selection is mouse_menu_selection.Grid then
			self.point.x = selection.x
			self.point.y = selection.y
		end
	end
	if self.parent then
		self.parent:claim_focus(nil, self)
	end
end

function NestedGridNode:handle_command(
    command: menu_types.MenuCommand
): MenuSignal
	local focused_leaf = self:get_focused_leaf()

	if focused_leaf ~= nil then
		if focused_leaf is ButtonCursor then
			focused_leaf.value = self:get_nested_grid_value()
		end
		return focused_leaf:handle_command(command)
	end
	log.debug("No focused leaf: "..tostring(self.point).." for "..self.id)
	return menu_signal.ignored()
end

function NestedGridNode:serialize(): SerializedMenu
	local state: SerializedNestedGridState = {
		type = "grid",
		point = self.point:copy(),
		tile_highlights = self.legal_tiles,
		children = {},
	}
	if self.path ~= nil then
		state.path = lists.map(function(p: Point): Point
			p:copy()
		end)(self.path)
	end
	local out: SerializedMenu = {
		state = state,
		data = {},
	}

	for _,child in ipairs(self.children) do
		local child_out = child.child:serialize()

		if child_out.data then
			maps.add_all(out.data, child_out.data)
		end

		if child_out.state and child.child.id then
			out.state.children[child.child.id] = child_out.state
		end
	end

	return out
end

function NestedGridNode:deserialize(state: menu_cursor.SerializedMenuState, data: {string: any}) 
	if state ~= nil and state is SerializedNestedGridState then
		self.point = state.point:copy()
		self.path = state.path
	end
	for _,child in ipairs(self.children) do
		child.child:deserialize(state and state.children[child.child.id] or nil, data)
	end
end

function NestedGridDefinition:to_cursor(
	parent: menu_cursor.MenuNode,
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
): menu_cursor.MenuNode
    local cursor: NestedGridNode = {
        type = "grid",
        parent = parent,
        x_max = 16,
        y_max = 16,
		point = point.of(0, 0),
    }
    if self.get_legal_tiles ~= nil then
        cursor.legal_tiles = self.get_legal_tiles(game_ctx, menu_ctx)
        if self.get_max_path_length ~= nil then
            cursor.max_path_length = self.get_max_path_length(game_ctx, menu_ctx)
            if self.get_path_anchor then
                cursor.path = {self.get_path_anchor(game_ctx, menu_ctx)}
            else
            	error("need path anchor!")
            end
        else
            cursor.path = nil
            cursor.max_path_length = nil
        end
    else
        cursor.legal_tiles = nil
    end
	setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (NestedGridNode as {string: any})[k] then
                return (NestedGridNode as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
        
    if self.children ~= nil then
		cursor.children = lists.map(function(c: NestedGridChildDefinition): NestedGridChild
			return c:to_cursor(cursor, game_ctx, menu_ctx, menu_state)
		end)(self.children)
		cursor.child_array = array_2d.new_from_function(cursor.x_max, cursor.y_max, function(p: Point): MenuNode
			return cursor:get_first_child(p, game_ctx, menu_ctx)
		end)
	else
		cursor.child_array = array_2d.new(cursor.x_max, cursor.y_max)
	end

	return cursor
end

function nested_grid.grid(
	id: string
): NestedGridDefinition
	return setmetatable({
		id = id,
	    type = "grid",
	    children = {},
	},{
	    __index = NestedGridDefinition
	})
end

function NestedGridDefinition:with_child(
	filter: function(Point, GameContext, MenuContext): boolean,
	child_definition: MenuNodeDefinition
): NestedGridDefinition
	pt.add(self.children, setmetatable({
		filter = filter,
		child = child_definition,
	},{
		__index = NestedGridChildDefinition,
	}))
	return self
end

function NestedGridDefinition:with_path_length(
	get_max_path_length: function(GameContext, MenuContext): integer
): NestedGridDefinition
	self.get_max_path_length = get_max_path_length
	return self
end

function NestedGridDefinition:with_path_anchor(
	get_path_anchor: function(GameContext, MenuContext): Point
): NestedGridDefinition
	self.get_path_anchor = get_path_anchor
	return self
end

function NestedGridDefinition:with_tile_highlights(
    get_legal_tiles: function(GameContext, MenuContext): array_2d.Array2D<MenuTileHighlight>
): NestedGridDefinition
	self.get_legal_tiles = get_legal_tiles
	return self
end

return nested_grid

