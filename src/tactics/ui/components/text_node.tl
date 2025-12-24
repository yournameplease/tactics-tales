require("src/tactics/ui/ui_context_manager")
require("src/tactics/ui/box")
local text = require("src/tactics/util/text")

global enum UITextColor
    "dark"
    "trim"
    "light"
end

global interface TextUIElement
    is UIElement
    draw_properties: text.DrawProperties
    text_color: UITextColor
end


global record TextNode
    is UIElement, TextUIElement
    func: function(UIContextManager): { string }
    text: { string }
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
    if props.text then
        box.text = props.text
    elseif props.func then
        box.func = props.func
    else
        error("Need either `text` or `func` for text node!")
    end
    if props.rows then
        box.rows = props.rows
        box.h = (box.rows) * (TEXT_HEIGHT + 2)
    end

    box.draw_properties = props.draw_properties or {}
    box.draw_properties.justify = box.draw_properties.justify or "left"
    box.draw_properties.direction = box.draw_properties.direction or "down"
    box.draw_properties.wrap = box.draw_properties.wrap or "ellipsis"

    box.transparent = props.transparent ~= false
    box.text_color = props.text_color or "dark"

    return box
end

function TextNode:draw(state: UIContextManager, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local lines = self.text or self.func(state)

    if self.rows then
        assert(
                #lines ==
                self.rows, "`func` should return expected number of rows"
        )
    end

    local colors <total>: {UITextColor: Color} = {
        dark = ui_theme.COLOR_INTERIOR_TEXT,
        trim = ui_theme.COLOR_TRIM,
        light = ui_theme.COLOR_DECORATION_SHADOW,
    }

    local text_obj = text.new(lines, self.draw_properties)
    text_obj:draw(
        self.x+self.internal_margin.l,
        self.y+self.internal_margin.t,
        self.w-self.internal_margin.l-self.internal_margin.r,
        self.h-self.internal_margin.t-self.internal_margin.b,
        colors[self.text_color]
    )
end

return TextNode
