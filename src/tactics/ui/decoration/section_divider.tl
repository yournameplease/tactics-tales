require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
require("src/tactics/ui/ui_context_manager")

local record SectionDivider
    is UIElement
end

setmetatable(SectionDivider, { __index = Box })

local section_divider = {}

function section_divider.new(h: integer): SectionDivider
    local box = Box.new({
		h = h,
		cross_stretch = true
	}) as SectionDivider
    setmetatable(box, {__index = SectionDivider})
    return box
end

function SectionDivider:draw(_: UIContextManager, _draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    -- Box._draw(self, state, ui_theme)

    local l = self.x
    local r = self.x + self.w - 1
    local t = self.y
	local h = self.h
	local c = ui_theme.COLOR_PAGE_DECOR

    for i=0,h-1 do
        pt.line(l + i, t + i, r - i, t + i, c)
    end
end

return section_divider
