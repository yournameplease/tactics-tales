require("src/ui/box")

global enum TextJustify
    "left"
    "center"
    "right"
end

global interface TextUIElement
    is UIElement
    justify: TextJustify
    rows: integer
end

global record TextNode
    is UIElement, TextUIElement
    func: function(GameContext): { string }
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
    box.justify = props.justify or "left"  -- "left", "right", "center"

    return box
end

global function draw_text_row(self: TextUIElement, i: integer, text: string, ui_theme: UITheme)
    local text_width = print(text, 0, -1000) as integer

    local t_x: integer
    if self.justify == "left" then
        t_x = self.x + self.padding + 1
    elseif self.justify == "center" then
        t_x = self.x + (self.w - 2 * (self.padding + 1) - text_width) // 2
    elseif self.justify == "right" then
        t_x = self.x + self.w - self.padding - 1 - text_width - 1
    else
        error("Unexpected value!")
    end

    print(text, t_x, self.y + self.padding + 1 + ((i-1) * (TEXT_HEIGHT + 2)), ui_theme.COLOR_INTERIOR_TEXT)
end

function TextNode:draw(state: GameContext, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local text = self.func(state)

    assert(
            #text ==
            self.rows, "`func` should return expected number of rows"
    )
    for i, text_row in ipairs(text) do
        draw_text_row(self, i, text_row, ui_theme)
    end

end

return TextNode
