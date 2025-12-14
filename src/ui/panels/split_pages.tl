require("src/ui/box")
require("src/systems/event_bus")
require("src/ui/components/text_node")
require("src/ui/components/message_log")
require("src/ui/ui_context_manager")
require("src/game/base_game_context")
local PageDivider = require("src/ui/decoration/page_divider")

local record SplitPages
    is UIElement, TextUIElement
end
 
function SplitPages.new(left: UIElement, right: UIElement): SplitPages
    local root = Box.new({
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

return SplitPages
