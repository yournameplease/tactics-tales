---@brief
--- Manages the rendering of complex, multi-part sprites using a skeleton hierarchy.
--- Calculates the position of each node and draws the complete character.

local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")
local point = require("src.tactics.util.point")

---@class SkeletonNode
---@field parent string
---@field sprite integer
---@field scale_x integer scale affects child offsets
---@field scale_y integer scale affects child offsets
---@field sprite_back integer
---@field ignore boolean
---@field computed_offset Point
---@field computed_scale_x integer
---@field computed_scale_y integer
---@field root Point
---@field anchors table<string, Point>

---@class SkeletonNodeDefinition
---@field parent string
---@field sprite integer
---@field scale_x integer
---@field scale_y integer
---@field sprite_back integer
---@field root PointRecord
---@field anchors table<string, PointRecord>

---@class AnimatedSkeleton
---@field draw fun(self: AnimatedSkeleton, base_sprite: integer, x: integer, y: integer)
---@field draw_backwards fun(self: AnimatedSkeleton, base_sprite: integer, x: integer, y: integer)

---@class AnimatedSkeletonImpl : AnimatedSkeleton
---@field nodes table<string, SkeletonNode>
---@field node_order string[]
---@field node_order_reversed string[]
local AnimatedSkeletonImpl = {}
AnimatedSkeletonImpl.__index = AnimatedSkeletonImpl

local animated_skeleton = {}

--- Create a new AnimatedSkeleton from node definitions and draw order.
---@param nodes table<string, SkeletonNodeDefinition>
---@param node_order string[]
---@return AnimatedSkeleton
function animated_skeleton.new(nodes, node_order)
    ---@type AnimatedSkeletonImpl
    local self = setmetatable({}, AnimatedSkeletonImpl)
    self.node_order = node_order
    self.node_order_reversed = lists.reverse(node_order)
    self.nodes = {}
    for k, n in pairs(nodes) do
        local node = {
            parent = n.parent,
            sprite = n.sprite,
            scale_x = n.scale_x or 1,
            scale_y = n.scale_y or 1,
            sprite_back = n.sprite_back,
            computed_offset = nil,
            computed_scale_x = nil,
            computed_scale_y = nil,
            root = n.root ~= nil and point.of_record(n.root) or nil,
            anchors = n.anchors ~= nil and maps.map(
                function(_, p)
                    return p ~= nil and point.of_record(p) or nil
                end
            )(n.anchors) or {},
        }
        self.nodes[k] = node
    end
    return self
end

--- Compute the cumulative offset for a node, memoizing the result.
---@param key string
function AnimatedSkeletonImpl:compute_offset(key)
    local node = self.nodes[key]
    if node.computed_offset ~= nil then
        -- memoized
    elseif node.parent == nil then
        node.computed_offset = point.of(0, 0)
        node.computed_scale_x = node.scale_x
        node.computed_scale_y = node.scale_y
    else
        self:compute_offset(node.parent)
        local parent = self.nodes[node.parent]
        assert(parent ~= nil, "Failed to find node with key " .. node.parent)
        local parent_anchor = parent.anchors[key]
        local child_anchor = node.root
        if child_anchor ~= nil then
            if parent_anchor == nil then
                node.ignore = true
            else
                node.computed_scale_x = parent.computed_scale_x * node.scale_x
                node.computed_scale_y = parent.computed_scale_y * node.scale_y
                node.computed_offset = parent.computed_offset
                    + parent_anchor
                    - child_anchor * point.of(node.computed_scale_x, node.computed_scale_y)
            end
        else
            node.computed_offset = parent.computed_offset
            node.computed_scale_x = parent.computed_scale_x
            node.computed_scale_y = parent.computed_scale_y
        end
    end
end

--- Compute offsets for all nodes.
function AnimatedSkeletonImpl:compute_offsets()
    for k, _ in pairs(self.nodes) do
        self:compute_offset(k)
    end
end

--- Draw a single node's sprite at the given position.
---@param node SkeletonNode
---@param base_sprite integer
---@param s integer sprite index offset
---@param x integer
---@param y integer
function AnimatedSkeletonImpl:draw_sprite(node, base_sprite, s, x, y)
    if s ~= nil and not node.ignore then
        local n_x = x + node.computed_offset.x
        local n_y = y + node.computed_offset.y
        local n_sx = node.computed_scale_x
        local n_sy = node.computed_scale_y
        if n_sx ~= 1 or n_sy ~= 1 then
            local spr_ud = get_spr(s)
            local s_w = spr_ud:width()
            local s_h = spr_ud:height()
            sspr(base_sprite + s,
                0, 0, s_w, s_h,
                n_x, n_y,
                s_w * n_sx, s_h * n_sy)
        else
            spr(base_sprite + s, n_x, n_y)
        end
    end
end

--- Draw all nodes in forward order.
---@param base_sprite integer
---@param x integer
---@param y integer
function AnimatedSkeletonImpl:draw(base_sprite, x, y)
    self:compute_offsets()
    for _, k in ipairs(self.node_order) do
        local node = self.nodes[k]
        if node ~= nil then
            local s = node.sprite
            self:draw_sprite(node, base_sprite, s, x, y)
        end
    end
end

--- Draw all nodes in reversed order using back sprites.
---@param base_sprite integer
---@param x integer
---@param y integer
function AnimatedSkeletonImpl:draw_backwards(base_sprite, x, y)
    self:compute_offsets()
    for _, k in ipairs(self.node_order_reversed) do
        local node = self.nodes[k]
        if node ~= nil then
            local s = node.sprite_back or node.sprite
            self:draw_sprite(node, base_sprite, s, x, y)
        end
    end
end

return animated_skeleton
