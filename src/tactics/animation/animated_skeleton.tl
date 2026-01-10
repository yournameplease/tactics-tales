local lists = require("src/tactics/util/lists")
local maps = require("src/tactics/util/maps")
local point = require("src/tactics/util/point")
local Point = point.Point
local PointRecord = point.PointRecord

local record SkeletonNode
	parent: string
	sprite: integer
	sprite_back: integer
	computed_offset: Point
	root: Point
	anchors: {string: Point}
end

local record SkeletonNodeDefinition
	parent: string
	sprite: integer
	sprite_back: integer
	root: PointRecord
	anchors: {string: PointRecord}
end

local interface AnimatedSkeleton
	draw: function(self, base_sprite: integer, x: integer, y: integer)
	draw_backwards: function(self, base_sprite: integer, x: integer, y: integer)
end

local animated_skeleton = {
	SkeletonNodeDefinition = SkeletonNodeDefinition,
	AnimatedSkeleton = AnimatedSkeleton,
}

local record AnimatedSkeletonImpl
	is AnimatedSkeleton
	nodes: { string: SkeletonNode }
	node_order: { string }
	node_order_reversed: { string }
end

function animated_skeleton.new(
	nodes: { string: SkeletonNodeDefinition },
	node_order: { string }
): AnimatedSkeleton
	local self: AnimatedSkeletonImpl = setmetatable({},{
		__index = AnimatedSkeletonImpl
	})
	self.node_order = node_order
	self.node_order_reversed = lists.reverse(node_order)
	self.nodes = {}
	for k,n in pairs(nodes) do
		local node: SkeletonNode = {
			parent = n.parent,
			sprite = n.sprite,
			sprite_back = n.sprite_back,
			computed_offset = nil,
			root = n.root ~= nil and point.of_record(n.root) or nil,
			anchors = n.anchors ~= nil and maps.map(
				function(_: string, p: PointRecord): Point
					return p ~= nil and point.of_record(p) or nil
				end
			)(n.anchors) or {},
		}
		self.nodes[k] = node
	end

	return self
end

function AnimatedSkeletonImpl:compute_offset(key: string)
	local node = self.nodes[key]
	if node.computed_offset ~= nil then
		-- memoized
	elseif node.parent == nil then
		node.computed_offset = point.of(0, 0)
	else
		self:compute_offset(node.parent)
		local parent = self.nodes[node.parent]
		assert(parent ~= nil, "Failed to find node with key "..node.parent)
		local parent_anchor = parent.anchors[key]
		local child_anchor = node.root
		if child_anchor ~= nil then
			node.computed_offset = parent.computed_offset + parent_anchor - child_anchor
		else
			node.computed_offset = parent.computed_offset
		end
	end
end

function AnimatedSkeletonImpl:compute_offsets()
	for k,_ in pairs(self.nodes) do
		self:compute_offset(k)
	end
end

function AnimatedSkeletonImpl:draw(base_sprite: integer, x: integer, y: integer)
	self:compute_offsets()
	for _,k in ipairs(self.node_order) do
		local node = self.nodes[k]
		if node ~= nil then
			local s = node.sprite
			if s ~= nil then
				local n_x = x + node.computed_offset.x
				local n_y = y + node.computed_offset.y
				pt.spr(base_sprite + s, n_x, n_y)
			end
		end
	end
end

function AnimatedSkeletonImpl:draw_backwards(base_sprite: integer, x: integer, y: integer)
	self:compute_offsets()
	for _,k in ipairs(self.node_order_reversed) do
		local node = self.nodes[k]
		if node ~= nil then
			local s = node.sprite_back or node.sprite
			if s ~= nil then
				local n_x = x + node.computed_offset.x
				local n_y = y + node.computed_offset.y
				pt.spr(base_sprite + s, n_x, n_y)
			end
		end
	end
end

return animated_skeleton
