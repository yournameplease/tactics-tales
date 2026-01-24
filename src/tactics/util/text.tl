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
    align: boolean
end

local interface Text
    set_width: function(self, w: integer)
    set_height: function(self, h: integer)
    set_lines: function(self, lines: {string})

    get_wrapped_rows: function(self): integer
    get_lines: function(self): {{string}}
    calculate_wrapping: function(self)

    draw: function(self, x: integer, y: integer, color: Color, line_counts: {integer})
    
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
    align: boolean

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
    self.align = draw_properties.align or false
    self.wrap = draw_properties.wrap or (self.align and "no_wrap" or "ellipsis")
    
    assert((not self.align) or (self.wrap == "no_wrap"), "Got `align` with a wrap mode")

    self.width = w
    self.height = h
    
    self.lines = text_lines(lines)

    return self
end

-- in pixels
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

local get_text_alignment_offset <total>:
{ Justify: function(row: string, w: integer): integer } = {
    ["left"] = function(_: string, _: integer): integer
        return 0
    end,
    ["center"] = function(row: string, w: integer): integer
        local line_width = width_of(row)
        return (w - line_width) // 2
    end,
    ["right"] = function(row: string, w: integer): integer
        local line_width = width_of(row)
        return w - line_width - 1
    end,
}


function TextImpl:draw_justified_text_row(
    row: string,
    x: integer,
    y: integer,
    justify: Justify,
    color: Color,
    row_number: integer,
    line_count: integer
)
	local x_offset = get_text_alignment_offset[justify](row, self.width)
	local t_x = x + x_offset
	local t_y = y + ((row_number-1) * (TEXT_ROW_HEIGHT))
    local out = row
    if line_count ~= nil then
        if line_count <= 0 then
            out = ""
        else
            out = pt.sub(out, 1, line_count)
        end
    end
    pt.print(out, t_x, t_y, color)
end

function TextImpl:draw_text_row(
    text_row: string,
    x: integer,
    y: integer,
    color: Color,
    row_number: integer,
    line_count: integer
)
    if self.align then
        local subrows = pt.split(text_row, "|")

        if (#subrows == 1) then
            self:draw_justified_text_row(
                subrows[1],
                x,
                y,
                self.justify,
                color,
                row_number,
                line_count
            )
        elseif (#subrows == 2) then
            local left = subrows[1]
            local right = subrows[2]

            self:draw_justified_text_row(
                left,
                x,
                y,
                "left",
                color,
                row_number,
                line_count
            )
            self:draw_justified_text_row(
                right,
                x,
                y,
                "right",
                color,
                row_number,
                line_count
            )
        elseif (#subrows == 3) then
            local left = subrows[1]
            local mid = subrows[2]
            local right = subrows[3]

            self:draw_justified_text_row(
                left,
                x,
                y,
                "left",
                color,
                row_number,
                line_count
            )
            self:draw_justified_text_row(
                right,
                x,
                y,
                "right",
                color,
                row_number,
                line_count
            )
            self:draw_justified_text_row(
                mid,
                x,
                y,
                "center",
                color,
                row_number,
                line_count
            )
        else
            error("Tried to align with more than 3 segments: "..text_row)
        end
    else
        self:draw_justified_text_row(
            text_row,
            x,
            y,
            self.justify,
            color,
            row_number,
            line_count
        )
    end
end

function TextImpl:calculate_wrapping()
    for _, paragraph in ipairs(self.lines) do
        if paragraph.wrapped_lines == nil then
            paragraph.wrapped_lines = self:apply_text_wrapping(paragraph.text, self.width)
        end
    end
end

function TextImpl:draw(
    x: integer,
    y: integer,
    color: Color,
    line_counts: {integer}
)
	profile("draw_text")

    self:calculate_wrapping()
    local row_count = 0
    for i, paragraph in ipairs(self.lines) do
        local line_count: integer = nil
        if line_counts ~= nil then
            line_count = line_counts[i]
        end
        for _, text_row in ipairs(paragraph.wrapped_lines) do
            row_count = row_count + 1
            self:draw_text_row(text_row, x, y, color, row_count, line_count)
            if line_count ~= nil then
                line_count = line_count - #text_row
            end 
        end
    end
	profile("draw_text")
end

return text


