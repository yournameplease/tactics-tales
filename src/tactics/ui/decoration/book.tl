local box = require("src.tactics.ui.box")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local book = {}

---@desc
--- A decorative UI spacer
--- resembling the seam between book pages.
function book.page_divider(width: integer): box.UIElement
    return box.builder("page_divider")
    :layout{
        height = "fill",
        width = width,
    }
	:on_draw(function(self: box.UIElement, _: UIContextManager, _draw_target_manager: DrawTargetManager, ui_theme: UITheme)
	    local l = self.rect.x
	    local r = self.rect.x + self.rect.w - 1
	    local t = self.rect.y
	    local b = self.rect.y + self.rect.h

	    local w = ((self.rect.w+1)>>1)-1
	    for i=0,w do

	        local c_l = i & 1 == 0 and ui_theme.COLOR_DECORATION_PRIMARY or ui_theme.COLOR_DECORATION_HIGHLIGHT
	        local c_r = i & 1 == 0 and ui_theme.COLOR_DECORATION_PRIMARY or ui_theme.COLOR_DECORATION_HIGHLIGHT

	        pt.line(l + i, t + i, l + i, b, c_l)
	        if i < w or w & 1 == 0 then
	            pt.line(r - i, t + i, r - i, b, c_r)
	        end
	    end
	end)
	:build()
end

---@desc
--- A decorative horizontal divider
--- between sections.
function book.section_divider(height: integer): box.UIElement
    return box.builder("section_divider")
    :layout{
        height = height,
        width = "fill",
    }
	:on_draw(function(self: box.UIElement, _: UIContextManager, _draw_target_manager: DrawTargetManager, ui_theme: UITheme)
	    local l = self.rect.x
	    local r = self.rect.x + self.rect.w - 1
	    local t = self.rect.y
		local h = self.rect.h
		local c = ui_theme.COLOR_PAGE_DECOR

	    for i=0,h-1 do
	        pt.line(l + i, t + i, r - i, t + i, c)
	    end
	end)
	:build()
end


local TRIM_PADDING = 3
---@desc
--- A decorative UI container styled to look like a book cover.
function book.book_box(
	width: integer,
	height: integer,
	pages_height: integer
): box.UIElement
    return box.builder("section_divider")
    :layout{
		dir="col",
		width=width,
		height=height,
		padding = {
			t = TRIM_PADDING,
			b = TRIM_PADDING+pages_height+1,
			l = TRIM_PADDING+1,
			r = TRIM_PADDING,
		}
    }
	:on_draw(function(self: box.UIElement, state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)

	    local l = self.rect.x
	    local r = self.rect.x + self.rect.w - 1
	    local t = self.rect.y
	    local b = self.rect.y + self.rect.h - 1
		local p = pages_height

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
	end)
	:build()
end


function book.split_pages(left: box.UIElement, right: box.UIElement): box.UIElement
    local root = box.builder("split_pages")
    :layout{
        dir="row",
    	width = 480,
    	height = 270,
    	padding = {
    		t = 4
    	}
    }
    :build()
    root:add(left)
    root:add(book.page_divider(7))
    root:add(right)

    return root 
end

function book.flex_page(): box.UIElement
	return box.builder("book_flex_page")
		:layout{
			dir="col",
			height = "fill",
			width = "fill",
			flex_grow = 1,
			padding = box.layout.padding(2),
		}
		:style{
			solid = true
		}
		:build()
end

function book.fit_page(): box.UIElement
	return box.builder("book_fit_page")
		:layout{
			dir="col",
			height = "fill",
			width = "fit_content",
		}
		:style{
			solid = true
		}
		:build()
end

return book
