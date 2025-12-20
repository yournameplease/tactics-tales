require("src/tactics/debug")
require("src/tactics/util")

-- TODO: allow different metric fonts

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

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

local record Text
	record TextDrawProperties
	    justify: TextJustify
	    text_direction: TextDirection
	    wrap_mode: WrapMode
	end
end

function Text.width(text: string): integer
    return pt.print(text, 0, -1000) as integer
end

function Text.apply_text_wrapping(text: string, width: integer, wrap_mode: WrapMode): {string}
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
            out = pt.sub(text,1, char_count)
            out_width = Text.width(out)
        until out_width > width or char_count == #text
        if out_width > width then
            return {pt.sub(text, 1,char_count-3).."..."}
        else
            return {text}
        end
    elseif wrap_mode == "wrap" then
        -- this needs unit tests x.x
        local out: {string} = {}
        local line_start = 1
        local previous_word_end: integer = -1
            while line_start <= #text and pt.sub(text, line_start, true) == ' ' do
                line_start = line_start + 1
            end
            if line_start > #text then 
                return out
            end
            local line_end = line_start
            local line = pt.sub(text, line_start, line_end)
            while line_end <= #text and Text.width(line) <= width do
                line_end = line_end + 1
                line = pt.sub(text, line_start, line_end)
                if (pt.sub(text, line_end, true) == ' ' and pt.sub(text, line_end-1, true) ~= ' ') then
                    previous_word_end = line_end - 1
                end
            end

            if line_end > #text and Text.width(line) <= width then
                -- end of text without overflow
                pt.add(out, line)
                return out
            elseif previous_word_end >= line_start then
                pt.add(out, pt.sub(text, line_start, previous_word_end))
                line_start = previous_word_end + 1
            else
                -- need to hyphenate
                pt.add(out, pt.sub(text, line_start, line_end-2)..'-')
				line_start = line_end - 1
            end
        end
    end
end

function Text.draw_text_row(text: string, x: integer, y: integer, color: Color)
    -- local t_x: integer
    -- if self.justify == "left" then
    --     t_x = self.x + self.padding + 1
    -- elseif self.justify == "center" then
    --     t_x = self.x + (self.w - 2 * (self.padding + 1) - line_width) // 2
    -- elseif self.justify == "right" then
    --     t_x = self.x + self.w - self.padding - 1 - line_width - 1
    -- else
    --     error("Unexpected value!")
    -- end
    -- pt.print(text, t_x, self.y + self.padding + 1 + ((i-1) * (TEXT_HEIGHT + 2)), ui_theme.COLOR_INTERIOR_TEXT)
    pt.print(text, x, y, color)
end

function Text.get_text_alignment_offset(text: string, w: integer, justify: TextJustify): integer
    local line_width = Text.width(text)
    if justify == "left" then
        return 0
    elseif justify == "center" then
        return (w - line_width) // 2
    elseif justify == "right" then
        return w - line_width - 1
    else
        error("Unexpected value!")
    end
end

function Text.draw(text: {string}, x: integer, y: integer, w: integer, h: integer, color: Color, properties: Text.TextDrawProperties)

    local wrapped_text: {{string}} = {}
    for _, t in ipairs(text) do
        pt.add(wrapped_text, Text.apply_text_wrapping(t, w, properties.wrap_mode))
        
    end

    local row_count = 0
    for _, paragraph in ipairs(wrapped_text) do
        for _, text_row in ipairs(paragraph) do
            row_count = row_count + 1
			local x_offset = Text.get_text_alignment_offset(text_row, w, properties.justify)

			local t_x = x + x_offset
			local t_y = y + ((row_count-1) * (TEXT_ROW_HEIGHT))
            Text.draw_text_row(text_row, t_x, t_y, color)
        end
    end
end

return Text


