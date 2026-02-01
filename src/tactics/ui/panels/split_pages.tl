---@brief
--- A container panel that creates a two-page/split-screen layout.

local box = require("src.tactics.ui.box")
local PageDivider = require("src.tactics.ui.decoration.page_divider")

local record SplitPages
    is box.UIElement 
end

local split_pages = {}

function split_pages.new(left: box.UIElement, right: box.UIElement): SplitPages
    local root = box.new({
        x=0, y=0,
        w=480, h=270,
        internal_margin = {t = 4},
        gap=0,
        padding=0, 
        dir="row",
        transparent = true
    })
    root:add(left)
    root:add(PageDivider.new(7))
    root:add(right)

    return root as SplitPages
end

return split_pages
