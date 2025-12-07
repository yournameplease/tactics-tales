require("src/ui/box")

local record PageDivider
    is UIElement
end

setmetatable(PageDivider, { __index = Box })


function PageDivider.new(width: integer): PageDivider
    local box = Box.new({ w=width, cross_stretch = true }) as PageDivider
    setmetatable(box, {__index = PageDivider})
    return box
end

function PageDivider:draw(state: GameContext, ui_theme: UITheme)
    -- Box._draw(self, state, ui_theme)

    local l = self.x
    local r = self.x + self.w
    local t = self.y
    local b = self.y + self.h

    for i=0,self.w-1 do
        local c_l = i & 1 == 0 and ui_theme.COLOR_DECORATION_HIGHLIGHT or ui_theme.COLOR_DECORATION_PRIMARY
        local c_r = i & 1 == 0 and ui_theme.COLOR_DECORATION_SHADOW or ui_theme.COLOR_DECORATION_PRIMARY

        line(l + i, t + i, l + i, b, c_l)
        line(r - i, t + i, r - i, b, c_r)
    end
end

return PageDivider
