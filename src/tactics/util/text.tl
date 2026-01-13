require("profiler")
local lists = require("src/tactics/util/lists")

-- TODO: allow different metric fonts

local enum Justify
    "left"
    "center"
    "right"
end

local enum Direction
    "down"
    "up"
end

local enum Wrap
    "no_wrap"
    "ellipsis"
    "wrap"
end

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

local record DrawProperties
    justify: Justify
    direction: Direction
    wrap: Wrap
end

local interface Text
    set_width: function(self, w: integer)
    set_height: function(self, h: integer)
    set_lines: function(self, lines: {string})

    get_wrapped_rows: function(self): integer
    get_lines: function(self): {{string}}
    calculate_wrapping: function(self)

    draw: function(self, x: integer, y: integer, color: Color)
    
end

local text = {
    Justify = Justify,
    Direction = Direction,
    Wrap = Wrap,
    DrawProperties = DrawProperties,
    Text = Text
}

local record TextLine
    text: string
    wrapped_lines: {string}
end

local function text_lines(lines: {string}): {TextLine}
    local out: {TextLine} = {}
    for _,l in ipairs(lines) do
        pt.add(out, {
            text = l
        })
    end
    return out
end

local record TextImpl
    is Text
    
    justify: Justify  
    direction: Direction  
    wrap: Wrap

    width: integer
    height: integer
    
    lines: {TextLine}
end

function text.new(lines: {string}, draw_properties: DrawProperties, w: integer, h: integer): Text
    local self: TextImpl = setmetatable({},{
        __index = TextImpl
    })

    self.justify = draw_properties.justify or "left"
    self.direction = draw_properties.direction or "down"
    self.wrap = draw_properties.wrap or "ellipsis"

    self.width = w
    self.height = h
    
    self.lines = text_lines(lines)

    return self
end

local function width_of(row: string): integer
    return pt.print(row, 0, -1000) as integer
end

function TextImpl:apply_text_wrapping(row: string, width: integer): {string}
    if row == '' then
        return {row}
    end

    if self.wrap == "no_wrap" then
        return {row}
    elseif self.wrap == "ellipsis" then
        local out: string
        local char_count = 0
        local out_width: integer
        repeat
            char_count = char_count + 1
            out = pt.sub(row,1, char_count)
            out_width = width_of(out)
        until out_width > width or char_count == #row
        if out_width > width then
            return {pt.sub(row, 1,char_count-3).."..."}
        else
            return {row}
        end
    elseif self.wrap == "wrap" then
        if width < 1 then
            log.warn("Can't wrap with non-positive width.")
            return {}
        end
        -- this needs unit tests x.x
        local out: {string} = {}
        log.trace("Wrapping text", row)
        local line_start = 1
        local previous_word_end: integer = -1
        while true do
            while line_start <= #row and pt.sub(row, line_start, true) == ' ' do
                line_start = line_start + 1
            end
            if line_start > #row then 
                return out
            end
            local line_end = line_start
            local line = pt.sub(row, line_start, line_end)
            while line_end <= #row and width_of(line) <= width do
                line_end = line_end + 1
                line = pt.sub(row, line_start, line_end)
                if (pt.sub(row, line_end, true) == ' ' and pt.sub(row, line_end-1, true) ~= ' ') then
                    previous_word_end = line_end - 1
                end
            end

            if line_end > #row and width_of(line) <= width then
                -- end of row without overflow
                pt.add(out, line)
                log.trace("Wrapping finished! ".. #out.. " rows.")
                return out
            elseif previous_word_end >= line_start then
                local sub_row = pt.sub(row, line_start, previous_word_end)
                log.trace("Wrapping", sub_row)
                pt.add(out, sub_row)
                line_start = previous_word_end + 1
            else
                local sub_row = pt.sub(row, line_start, line_end-2)
                log.trace("Hyphenating", sub_row)
                -- need to hyphenate
                pt.add(out, sub_row..'-')
    			line_start = line_end - 1
            end
        end
    end
end

function TextImpl:set_width(w: integer)
    if self.width ~= w then
        for _,l in ipairs(self.lines) do
            l.wrapped_lines = nil
        end
    end
    self.width = w
end

function TextImpl:set_height(h: integer)
    self.height = h
end

function TextImpl:set_lines(lines: {string})
    if #lines ~= #self.lines then
        self.lines = text_lines(lines)
    else
        for i,l in ipairs(lines) do
            if self.lines[i].text ~= l then
                self.lines[i].text = l
                self.lines[i].wrapped_lines = nil
            end
        end
    end
end

function TextImpl:get_wrapped_rows(): integer
    return lists.sum(function(l: TextLine): integer
        if l.wrapped_lines == nil then
            l.wrapped_lines = self:apply_text_wrapping(l.text, self.width)
        end
        log.trace("wrapped lines", l.text, l.wrapped_lines)
        return #l.wrapped_lines
    end)(self.lines) as integer
end

function TextImpl:get_lines(): {{string}}
    return lists.map(
        function(l: TextLine): {string}
            if l.wrapped_lines == nil then
                l.wrapped_lines = self:apply_text_wrapping(l.text, self.width)
            end
            return l.wrapped_lines
        end
    )(self.lines)
end

function TextImpl:draw_text_row(row: string, x: integer, y: integer, color: Color)
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
    pt.print(row, x, y, color)
end

function TextImpl:get_text_alignment_offset(row: string, w: integer): integer
    local line_width = width_of(row)
    if self.justify == "left" then
        return 0
    elseif self.justify == "center" then
        return (w - line_width) // 2
    elseif self.justify == "right" then
        return w - line_width - 1
    else
        error("Unexpected value!")
    end
end

function TextImpl:calculate_wrapping()
    for _, paragraph in ipairs(self.lines) do
        if paragraph.wrapped_lines == nil then
            paragraph.wrapped_lines = self:apply_text_wrapping(paragraph.text, self.width)
        end
    end
end

function TextImpl:draw(x: integer, y: integer, color: Color)
	profile("draw_text")

    self:calculate_wrapping()
    local row_count = 0
    for _, paragraph in ipairs(self.lines) do
        for _, text_row in ipairs(paragraph.wrapped_lines) do
            row_count = row_count + 1
			local x_offset = self:get_text_alignment_offset(text_row, self.width)

			local t_x = x + x_offset
			local t_y = y + ((row_count-1) * (TEXT_ROW_HEIGHT))
            self:draw_text_row(text_row, t_x, t_y, color)
        end
    end
	profile("draw_text")
end

return text


