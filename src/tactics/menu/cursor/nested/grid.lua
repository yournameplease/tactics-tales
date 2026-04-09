---@brief
--- Implements a menu cursor for navigating a 2D grid, used for
--- selecting tiles on the battle map.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local fp = require("src.tactics.util.fp")
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local point = require("src.tactics.util.point")
local array_2d = require("src.tactics.util.array_2d")
local pathfinding = require("src.tactics.battle.pathfinding")

---@class NestedGridValue
---@field point Point
---@field path Point[]|nil Path from the anchor to the selected point.

---@class NestedGridChild
---@field filter fun(p: Point, game_ctx: GameContext, menu_ctx: MenuContext): boolean Predicate; true means this child is active at position p.
---@field child MenuNode

---@class NestedGridNode : MenuContainer
---@field type "grid"
---@field point Point Current cursor position (0-indexed).
---@field x_max integer Grid width in tiles.
---@field y_max integer Grid height in tiles.
---@field path Point[]|nil Pathfinding path from the anchor to the cursor position.
---@field legal_tiles userdata|nil Userdata bitmask of valid and reachable tiles.
---@field max_path_length integer|nil Maximum allowed path length.
---@field children NestedGridChild[]
---@field text_array Array2D|nil Per-tile text overlay computed by text_function.
---@field text_function (fun(p: Point, game_ctx: GameContext, menu_ctx: MenuContext): string)|nil
local NestedGridNode = {}
NestedGridNode.__index = NestedGridNode

---@class NestedGridChildDefinition
---@field filter fun(p: Point, game_ctx: GameContext, menu_ctx: MenuContext): boolean
---@field child MenuNodeDefinition
local NestedGridChildDefinition = {}
NestedGridChildDefinition.__index = NestedGridChildDefinition

---@class NestedGridDefinition : MenuContainerDefinition
---@field type "grid"
---@field x_max integer
---@field y_max integer
---@field children NestedGridChildDefinition[]
---@field text_function (fun(p: Point, game_ctx: GameContext, menu_ctx: MenuContext): string)|nil
---@field get_tile_highlights (fun(game_ctx: GameContext, menu_ctx: MenuContext): userdata)|nil
---@field get_path_anchor (fun(game_ctx: GameContext, menu_ctx: MenuContext): Point)|nil
---@field get_max_path_length (fun(game_ctx: GameContext, menu_ctx: MenuContext): integer)|nil
---@field get_initial_point (fun(game_ctx: GameContext, menu_ctx: MenuContext): Point)|nil
local NestedGridDefinition = {}
NestedGridDefinition.__index = NestedGridDefinition

---@class SerializedNestedGridState : SerializedMenuState
---@field type "grid"
---@field point Point Cursor position at serialization time.
---@field path Point[]|nil Pathfinding path at serialization time.
---@field tile_highlights userdata|nil Legal-tile bitmask at serialization time.

local nested_grid = {
    NestedGridNode = NestedGridNode,
    NestedGridDefinition = NestedGridDefinition,
}

--- Initialize a NestedGridDefinition from a property table.
---@param props NestedGridDefinition
---@return NestedGridDefinition
function nested_grid.definition(props)
    props.type = "grid"
    return setmetatable(props, { __index = NestedGridDefinition })
end

--- Build a NestedGridChild cursor from this child definition.
---@param parent NestedGridNode
---@param game_ctx GameContext
---@param menu_ctx MenuContext
---@param menu_state MenuState
---@return NestedGridChild
function NestedGridChildDefinition:to_cursor(parent, game_ctx, menu_ctx, menu_state)
    return setmetatable({
        child = self.child:to_cursor(parent, game_ctx, menu_ctx, menu_state)
    }, { __index = self })
end

--- Return the first child whose filter matches position p.
---@param p Point
---@param game_context GameContext
---@param menu_ctx MenuContext
---@return MenuNode|nil
function NestedGridNode:get_first_child(p, game_context, menu_ctx)
    for _, child in ipairs(self.children) do
        if child.filter(p, game_context, menu_ctx) then
            return child.child
        end
    end
end

--- Return all children whose filters match the current cursor position.
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuNode[]
function NestedGridNode:get_focused_leaves(menu_ctx, game_ctx)
    return fp.pipeline_2(
        lists.filter(function(child)
            return child.filter(self.point, game_ctx, menu_ctx)
        end),
        lists.map(function(child)
            return child.child
        end)
    )(self.children)
end

--- Return all children regardless of the current cursor position.
---@return MenuNode[]
function NestedGridNode:get_all_focused_leaves()
    return lists.map(function(child)
        return child.child
    end)(self.children)
end

--- Return a value snapshot of the current grid position and path.
---@return NestedGridValue
function NestedGridNode:get_nested_grid_value()
    return {
        point = self.point,
        path = self.path,
    }
end

--- Move the cursor to p (clamped to bounds) and update the path if pathfinding is active.
---@param p Point Desired destination.
---@return boolean moved True when the cursor position actually changed.
function NestedGridNode:move_cursor(p)
    local prev_point = self.point:copy()
    self.point.x = math.max(0, math.min(p.x, self.x_max - 1))
    self.point.y = math.max(0, math.min(p.y, self.y_max - 1))

    if self.legal_tiles and self.path and self.point ~= prev_point then
        if self.legal_tiles:get(self.point.x, self.point.y) & HIGHLIGHT.IS_VALID ~= 0 then
            local tiles = self.legal_tiles & HIGHLIGHT.IS_VALID >> 1
            self.path = pathfinding.extend_path_to_point(self.path, self.point, self.max_path_length, tiles)
        end
    end

    return self.point ~= prev_point
end

--- Handle joypad input, propagating to focused leaves then moving the cursor.
---@param joy Joypad
---@param commands string[]
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuSignal
function NestedGridNode:update_joy(joy, commands, menu_ctx, game_ctx)
    local focused_leaves = self:get_focused_leaves(menu_ctx, game_ctx)

    local signal = menu_signal.ignored()
    for _, leaf in ipairs(focused_leaves) do
        if leaf ~= nil then
            if leaf.type == "button" then
                leaf.value = self:get_nested_grid_value()
            end
            signal = leaf:update_joy(joy, commands, menu_ctx, game_ctx)
            if signal.type ~= "ignored" then
                break
            end
        end
    end

    if signal.type ~= "ignored" then return signal end
    local moved = false

    if joy.dxp ~= 0 or joy.dyp ~= 0 then
        local next_p = self.point + point.of(joy.dxp, joy.dyp)
        moved = self:move_cursor(next_p)
    end

    if moved then
        return menu_signal.consumed()
    else
        return menu_signal.ignored()
    end
end

--- Handle mouse input by propagating to focused leaves.
---@param mouse Mouse
---@param selection MenuMouseSelection
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuSignal
function NestedGridNode:update_mouse(mouse, selection, menu_ctx, game_ctx)
    local focused_leaves = self:get_focused_leaves(menu_ctx, game_ctx)

    for _, leaf in ipairs(focused_leaves) do
        local sig = leaf:update_mouse(mouse, selection, menu_ctx, game_ctx)
        if sig.type ~= "ignored" then
            return sig
        end
    end

    return menu_signal.ignored()
end

--- Remove focus from this node and all of its children.
function NestedGridNode:lose_focus()
    self.has_focus = false
    local all_leaves = self:get_all_focused_leaves()
    for _, leaf in ipairs(all_leaves) do
        leaf:lose_focus()
    end
end

--- Restore focus to this node and all of its children.
function NestedGridNode:refresh_focus()
    self.has_focus = true
    local all_leaves = self:get_all_focused_leaves()
    for _, leaf in ipairs(all_leaves) do
        leaf:refresh_focus()
    end
end

--- Claim focus, optionally moving the cursor to the mouse position.
---@param selection MenuMouseSelection|nil
---@param _child MenuNode
function NestedGridNode:claim_focus(selection, _child)
    self.has_focus = true
    if selection ~= nil then
        if selection.type == "grid" then
            ---@cast selection GridMouseSelection
            self:move_cursor(point.of(selection.x, selection.y))
        end
    end
    if self.parent then
        self.parent:claim_focus(nil, self)
    end
end

--- Dispatch a command to the first focused leaf that handles it.
---@param command string MenuCommand value.
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuSignal
function NestedGridNode:handle_command(command, menu_ctx, game_ctx)
    local focused_leaves = self:get_focused_leaves(menu_ctx, game_ctx)

    for _, leaf in ipairs(focused_leaves) do
        if leaf ~= nil then
            log.debug("Focused leaf: " .. leaf.id .. " at " .. tostring(self.point) .. " for " .. self.id)
            if leaf.type == "button" then
                leaf.value = self:get_nested_grid_value()
            end
            local sig = leaf:handle_command(command, menu_ctx, game_ctx)
            if sig.type ~= "ignored" then
                return sig
            end
        end
    end
    log.debug("No focused leaf: " .. tostring(self.point) .. " for " .. self.id)
    return menu_signal.ignored()
end

--- Serialize the grid cursor position, path, and all child states.
---@return SerializedMenu
function NestedGridNode:serialize()
    ---@type SerializedNestedGridState
    local state = {
        type = "grid",
        point = self.point:copy(),
        path = self.path,
        tile_highlights = self.legal_tiles,
        children = {},
    }
    ---@type SerializedMenu
    local out = {
        state = state,
        data = {},
    }

    for _, child in ipairs(self.children) do
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

--- Restore the grid position, path, and child states from serialized data.
---@param state SerializedMenuState|nil
---@param data table<string, any>
function NestedGridNode:deserialize(state, data)
    if state ~= nil and state.type == "grid" then
        ---@cast state SerializedNestedGridState
        self.point = state.point:copy()
        self.path = state.path
        self.legal_tiles = state.tile_highlights
    end
    for _, child in ipairs(self.children) do
        child.child:deserialize(state and state.children and state.children[child.child.id] or nil, data)
    end
end

--- Recompute text overlays and propagate recompute to all children.
---@param game_ctx GameContext
---@param menu_ctx MenuContext
function NestedGridNode:recompute(game_ctx, menu_ctx)
    if self.text_function then
        self.text_array = array_2d.new_from_function(self.x_max, self.y_max, function(p)
            return self.text_function(p, game_ctx, menu_ctx)
        end)
    end
    for _, child in ipairs(self.children) do
        child.child:recompute(game_ctx, menu_ctx)
    end
end

--- Build a NestedGridNode from this definition.
---@param parent MenuNode|nil
---@param game_ctx GameContext
---@param menu_ctx MenuContext
---@param menu_state MenuState
---@return MenuNode
function NestedGridDefinition:to_cursor(parent, game_ctx, menu_ctx, menu_state)
    local cursor = {
        type = "grid",
        parent = parent,
        x_max = self.x_max,
        y_max = self.y_max,
        point = point.of(0, 0),
        has_focus = false,
    }

    if self.get_tile_highlights ~= nil then
        cursor.legal_tiles = self.get_tile_highlights(game_ctx, menu_ctx)
        if self.get_max_path_length ~= nil then
            cursor.max_path_length = self.get_max_path_length(game_ctx, menu_ctx)
            log.debug("Max Path Length: " .. cursor.max_path_length)
            if self.get_path_anchor then
                cursor.path = { self.get_path_anchor(game_ctx, menu_ctx) }
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

    setmetatable(cursor, { __index = function(_, k)
        if NestedGridNode[k] then
            return NestedGridNode[k]
        end
        return self[k]
    end })

    if self.get_initial_point then
        local initial_point = self.get_initial_point(game_ctx, menu_ctx)
        if initial_point ~= nil then
            cursor:move_cursor(initial_point)
        end
    end

    if self.children ~= nil then
        cursor.children = lists.map(function(c)
            return c:to_cursor(cursor, game_ctx, menu_ctx, menu_state)
        end)(self.children)
    else
        error("Probably an error, grid with no children")
    end

    if self.text_function then
        cursor.text_array = array_2d.new_from_function(cursor.x_max, cursor.y_max, function(p)
            return self.text_function(p, game_ctx, menu_ctx)
        end)
    end

    return cursor
end

--- Create a new NestedGridDefinition builder.
---@param id string
---@param x_max integer Grid width in tiles.
---@param y_max integer Grid height in tiles.
---@return NestedGridDefinition
function nested_grid.grid(id, x_max, y_max)
    return setmetatable({
        id = id,
        type = "grid",
        x_max = x_max,
        y_max = y_max,
        children = {},
    }, { __index = NestedGridDefinition })
end

--- Add a conditional child, active only when filter returns true at the current position.
---@param filter fun(p: Point, game_ctx: GameContext, menu_ctx: MenuContext): boolean
---@param child_definition MenuNodeDefinition
---@return NestedGridDefinition
function NestedGridDefinition:with_child(filter, child_definition)
    table.insert(self.children, setmetatable({
        filter = filter,
        child = child_definition,
    }, { __index = NestedGridChildDefinition }))
    return self
end

--- Add a child that is active at every grid position.
---@param child_definition MenuNodeDefinition
---@return NestedGridDefinition
function NestedGridDefinition:with_common_child(child_definition)
    table.insert(self.children, setmetatable({
        filter = function() return true end,
        child = child_definition,
    }, { __index = NestedGridChildDefinition }))
    return self
end

--- Set a function that supplies per-tile text overlays.
---@param text_function fun(p: Point, game_ctx: GameContext, menu_ctx: MenuContext): string
---@return NestedGridDefinition
function NestedGridDefinition:with_text_function(text_function)
    self.text_function = text_function
    return self
end

--- Set a function that returns the maximum allowed path length.
---@param get_max_path_length fun(game_ctx: GameContext, menu_ctx: MenuContext): integer
---@return NestedGridDefinition
function NestedGridDefinition:with_path_length(get_max_path_length)
    self.get_max_path_length = get_max_path_length
    return self
end

--- Set a function that returns the path anchor (starting tile for pathfinding).
---@param get_path_anchor fun(game_ctx: GameContext, menu_ctx: MenuContext): Point
---@return NestedGridDefinition
function NestedGridDefinition:with_path_anchor(get_path_anchor)
    self.get_path_anchor = get_path_anchor
    return self
end

--- Set a function that returns the tile-highlight bitmask userdata.
---@param get_tile_highlights fun(game_ctx: GameContext, menu_ctx: MenuContext): userdata
---@return NestedGridDefinition
function NestedGridDefinition:with_tile_highlights(get_tile_highlights)
    self.get_tile_highlights = get_tile_highlights
    return self
end

--- Set a function that returns the initial cursor position.
---@param get_initial_point fun(game_ctx: GameContext, menu_ctx: MenuContext): Point
---@return NestedGridDefinition
function NestedGridDefinition:with_initial_point(get_initial_point)
    self.get_initial_point = get_initial_point
    return self
end

return nested_grid
