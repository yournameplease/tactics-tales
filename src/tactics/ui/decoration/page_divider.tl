require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
require("src/tactics/ui/ui_context_manager")

local record PageDivider
    is UIElement
end

setmetatable(PageDivider, { __index = Box })


function PageDivider.new(width: integer): PageDivider
    local box = Box.new({ w=width, cross_stretch = true }) as PageDivider
    setmetatable(box, {__index = PageDivider})
    return box
end

function PageDivider:draw(_: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    -- Box._draw(self, state, ui_theme)

    local l = self.x
    local r = self.x + self.w - 1
    local t = self.y
    local b = self.y + self.h

    local w = ((self.w+1)>>1)-1
    for i=0,w do

        local c_l = i & 1 == 0 and ui_theme.COLOR_DECORATION_PRIMARY or ui_theme.COLOR_DECORATION_HIGHLIGHT
        local c_r = i & 1 == 0 and ui_theme.COLOR_DECORATION_PRIMARY or ui_theme.COLOR_DECORATION_HIGHLIGHT

        pt.line(l + i, t + i, l + i, b, c_l)
        if i < w or w & 1 == 0 then
            pt.line(r - i, t + i, r - i, b, c_r)
        end
    end
end

return PageDivider
