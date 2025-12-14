require("src/ui/ui_context_manager")
require("src/ui/box")
local Text = require("src/util/text")

global interface TextUIElement
    is UIElement
    draw_properties: Text.TextDrawProperties
end


global record TextNode
    is UIElement, TextUIElement
    func: function(UIContextManager): { string }
    rows: integer
end

setmetatable(TextNode, { __index = Box })

local TEXT_HEIGHT = 8

-- extra props
-- func = text callback
-- rows = defaults to 1
-- justify
function TextNode.new(props: TextNode): TextNode
    local box = Box.new(props) as TextNode
    setmetatable(box, { __index = TextNode })

    box.padding = props.padding or 0
    box.decoration_padding = 0
    box.func = props.func or error("Need text getter `func`")
    box.rows = props.rows or 1
    box.h = (box.rows) * (TEXT_HEIGHT + 2)

    props.draw_properties = props.draw_properties or {}
    box.draw_properties = {
        justify = "left",
        text_direction = "down",
        wrap_mode = "ellipsis",
    }
    box.draw_properties.justify = props.draw_properties.justify or box.draw_properties.justify
    box.draw_properties.text_direction = props.draw_properties.text_direction or box.draw_properties.text_direction
    box.draw_properties.wrap_mode = box.draw_properties.wrap_mode

    return box
end

function TextNode:draw(state: UIContextManager, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local text = self.func(state)

    assert(
            #text ==
            self.rows, "`func` should return expected number of rows"
    )

    Text.draw(text,
        self.x+self.internal_margin.l,
        self.y+self.internal_margin.t,
        self.w-self.internal_margin.l-self.internal_margin.r,
        self.h-self.internal_margin.t-self.internal_margin.b,
        ui_theme.COLOR_INTERIOR_TEXT, self.draw_properties)
end

return TextNode
