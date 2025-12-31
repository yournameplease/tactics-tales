local box = require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager

local record BookBox
    is box.UIElement
	pages_height: integer
end
setmetatable(BookBox, { __index = box.Box })

local TRIM_PADDING = 3

local book_box = {}

function book_box.new(
	width: integer,
	height: integer,
	pages_height: integer
): box.UIElement
    local self = box.new({
		dir="col",
		w=width,
		h=height,
		internal_margin = {
			t = TRIM_PADDING,
			b = TRIM_PADDING+pages_height+1,
			l = TRIM_PADDING+1,
			r = TRIM_PADDING,
		}
	}) as BookBox
    setmetatable(self, {__index = BookBox})
	self.pages_height = pages_height
    return self
end

function BookBox:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    -- Box._draw(self, state, ui_theme)

    local l = self.x
    local r = self.x + self.w - 1
    local t = self.y
    local b = self.y + self.h - 1
	local p = self.pages_height

	pt.line(l,t+1,l,b-1,ui_theme.COLOR_DECORATION_SHADOW)
	pt.rectfill(l+1,t+p,r,b,ui_theme.COLOR_DECORATION_SHADOW)

    local p_2 = ((p+1)>>1)-1
    for i=0,p_2 do

        local c = i & 1 == 0 and ui_theme.COLOR_DECORATION_HIGHLIGHT or ui_theme.COLOR_DECORATION_PRIMARY

        pt.line(l+1+i, b-1-i, r-1, b-1-i, c)
        if i < p_2 or p_2 & 1 == 0 then
	        pt.line(l+1+i, b-p+i, r-1, b-p+i, c)
        end
    end

	pt.rectfill(l+1,t,r,b-p-1,ui_theme.COLOR_DECORATION_PRIMARY)

	pt.rect(l+1+2,t+2,r-2,b-p-1-2,ui_theme.COLOR_TRIM)

    for _, child in ipairs(self.children) do
        child:draw(state, draw_target_manager, ui_theme)
    end
end

return book_box
