local point = require("src/tactics/util/point")
local Point = point.Point

local record SkeletonNode
	parent: string
	sprite: integer
	root: Point
	anchors: {string: Point}
end

local interface AnimatedSkeleton
	draw: function(self)
	draw_backwards: function(self)
end

local record AnimatedSkeletonImpl
	nodes: { string: SkeletonNode }
	node_order: { string }
end

