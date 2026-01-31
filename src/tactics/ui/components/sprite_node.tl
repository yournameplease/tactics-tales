local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local box = require("src.tactics.ui.box")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager

local record SpriteNode
    is box.UIElement
	sprite_function: function(UIContextManager): integer
end
setmetatable(SpriteNode, { __index = box.Box })

local sprite_node = {}

function sprite_node.static(
	sprite: integer,
	props: box.UIElement
): box.UIElement
    local self = box.new(props) as SpriteNode
    setmetatable(self, {__index = SpriteNode})
    self.sprite_function = function(_: UIContextManager): integer
		return sprite
	end
    return self
end

function sprite_node.dynamic(
	sprite_function: function(state: UIContextManager): integer,
	props: box.UIElement
): box.UIElement
    local self = box.new(props) as SpriteNode
    setmetatable(self, {__index = SpriteNode})
    self.sprite_function = sprite_function 
    return self
end

function SpriteNode:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    box.Box._draw(self, state, draw_target_manager, ui_theme)

	pt.spr(
		self.sprite_function(state),
		self.x + self.internal_margin.l,
		self.y + self.internal_margin.t
	)
end

return sprite_node

