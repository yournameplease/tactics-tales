require("src/ui/ui_context_manager")
require("src/ui/box")

global enum TextJustify
    "left"
    "center"
    "right"
end

global enum TextDirection
    "down"
    "up"
end

global enum WrapMode
    "no_wrap"
    "ellipsis"
    "wrap"
end

global interface TextUIElement
    is UIElement
    justify: TextJustify
    rows: integer
    text_direction: TextDirection
    wrap_mode: WrapMode
end


global record TextNode
    is UIElement, TextUIElement
    func: function(UIContextManager): { string }
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
    box.wrap_mode = props.wrap_mode or "ellipsis"

    return box
end

local function text_width(text: string): integer
    return print(text, 0, -1000) as integer
end

global function draw_text_row(self: TextUIElement, i: integer, text: string, ui_theme: UITheme)
    local line_width = text_width(text)

    local t_x: integer
    if self.justify == "left" then
        t_x = self.x + self.padding + 1
    elseif self.justify == "center" then
        t_x = self.x + (self.w - 2 * (self.padding + 1) - line_width) // 2
    elseif self.justify == "right" then
        t_x = self.x + self.w - self.padding - 1 - line_width - 1
    else
        error("Unexpected value!")
    end

    print(text, t_x, self.y + self.padding + 1 + ((i-1) * (TEXT_HEIGHT + 2)), ui_theme.COLOR_INTERIOR_TEXT)
end

local function apply_text_wrapping(text: string, width: integer, wrap_mode: WrapMode): {string}
    if text == '' then
        return {text}
    end

    if wrap_mode == "no_wrap" then
        return {text}
    elseif wrap_mode == "ellipsis" then
        local out: string
        local char_count = 0
        local out_width: integer
        repeat
            char_count = char_count + 1
            out = sub(text,1, char_count)
            out_width = text_width(out)
        until out_width > width or char_count == #text
        if out_width > width then
        LOG.debug("WIDTH", out_width, width)
            return {sub(text, 1,char_count-3).."..."}
        else
            return {text}
        end
    elseif wrap_mode == "wrap" then
        -- this needs unit tests x.x
        local out: {string} = {}
        local line_start = 1
        local previous_word_end: integer
        local line_width: integer
        while true do
            while line_start <= #text and sub(text, line_start, true) == ' ' do
                line_start = line_start + 1
            end
            local line_end = line_start
            local line = sub(text, line_start, line_end)
            while line_end <= #text and text_width(line) <= width do
                line_end = line_end + 1
                line = sub(text, line_start, line_end)
                if (sub(text, line_end, true) == ' ' and sub(text, line_end-1, true) ~= ' ') then
                    previous_word_end = line_end - 1
                end
            end

            if line_start > #text then 
                return out
            elseif previous_word_end >= line_start then
                add(out, sub(text, line_start, previous_word_end))
            elseif line_start > #text then 
                return out
            else
                -- need to hyphenate
                return out
            end
        end
    end
end

global function draw_text(text: {string})

end

function TextNode:draw(state: UIContextManager, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local text = self.func(state)

    assert(
            #text ==
            self.rows, "`func` should return expected number of rows"
    )

    local wrapped_text: {{string}} = {}
    for _, t in ipairs(text) do
        add(wrapped_text, apply_text_wrapping(t, self.w, self.wrap_mode))
    end

    local row_count = 0
    for i, paragraph in ipairs(wrapped_text) do
        for _, text_row in ipairs(paragraph) do
            row_count = row_count + 1
            draw_text_row(self, row_count, text_row, ui_theme)
        end
    end

end

return TextNode
