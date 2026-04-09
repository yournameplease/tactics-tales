---@brief
--- A utility for handling text layout, including wrapping, justification,
--- and alignment for UI rendering.

require("profiler")
local lists = require("src.tactics.util.lists")

-- TODO: allow different metric fonts

---@alias Justify "left"|"center"|"right"
---@alias Direction "down"|"up"
---@alias Wrap "no_wrap"|"ellipsis"|"wrap"

---@class DrawProperties
---@field justify Justify How to align text horizontally within the available width.
---@field direction Direction Whether rows flow downward or upward from the draw origin.
---@field wrap Wrap Behaviour when a line exceeds the available width.
---@field align boolean When true, `|`-delimited segments are drawn left, center, and right.

---@class Text
---@field set_width fun(self: Text, w: integer)
---@field set_height fun(self: Text, h: integer)
---@field set_lines fun(self: Text, lines: string[])
---@field get_wrapped_rows fun(self: Text): integer
---@field get_lines fun(self: Text): string[][]
---@field calculate_wrapping fun(self: Text)
---@field draw fun(self: Text, x: integer, y: integer, color: Color, line_counts: integer[])
---@field draw_one fun(self: Text, row_num: integer, x: integer, y: integer, color: Color, line_count: integer)

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

---@class TextLine
---@field text string
---@field wrapped_lines string[]|nil Cached wrap result; nil means wrapping not yet computed.

---@param lines string[]
---@return TextLine[]
local function text_lines(lines)
    local out = {}
    for _, l in ipairs(lines) do
        table.insert(out, { text = l })
    end
    return out
end

---@class TextImpl : Text
---@field justify Justify How to align text horizontally.
---@field direction Direction Whether rows flow downward or upward.
---@field wrap Wrap Wrapping mode applied when a line exceeds `width`.
---@field align boolean When true, use `|`-column alignment instead of uniform justification.
---@field width integer Draw area width in pixels.
---@field height integer Draw area height in pixels.
---@field lines TextLine[] Paragraphs, each with its cached wrapped sub-lines.

local TextImpl = {}

local text = {}

--- Construct a Text object from a list of paragraph strings and display properties.
---@param lines string[] Paragraph strings to display.
---@param draw_properties DrawProperties Layout and wrapping configuration.
---@param w integer
---@param h integer
---@return Text
function text.new(lines, draw_properties, w, h)
    local self = setmetatable({}, { __index = TextImpl })

    self.justify   = draw_properties.justify or "left"
    self.direction = draw_properties.direction or "down"
    self.align     = draw_properties.align or false
    self.wrap      = draw_properties.wrap or (self.align and "no_wrap" or "ellipsis")

    assert((not self.align) or (self.wrap == "no_wrap"), "Got `align` with a wrap mode")

    self.width  = w
    self.height = h
    self.lines  = text_lines(lines)

    return self
end

--- Return the pixel width of `row` as rendered by the current font.
---@param row string
---@return integer
local function width_of(row)
    local w, _ = pt.print(row, 0, -1000)
    return w
end

--- Break or truncate `row` to fit within `width` pixels according to `self.wrap`.
---@param row string The raw text to wrap or truncate.
---@param width integer Maximum pixel width for a single output line.
---@return string[] Lines that each fit within `width`.
function TextImpl:apply_text_wrapping(row, width)
    if row == '' then return {row} end

    if self.wrap == "no_wrap" then
        return {row}
    elseif self.wrap == "ellipsis" then
        if width == nil or width < 1 then
            log.warn("Can't wrap with non-positive width.")
            return {row}
        end
        local out
        local char_count = 0
        local out_width
        repeat
            char_count = char_count + 1
            out = string.sub(row, 1, char_count)
            out_width = width_of(out)
        until out_width > width or char_count == #row
        if out_width > width then
            return {string.sub(row, 1, char_count - 3) .. "..."}
        else
            return {row}
        end
    elseif self.wrap == "wrap" then
        if width == nil or width < 1 then
            log.warn("Can't wrap with non-positive width.")
            return {row}
        end
        local out = {}
        log.trace("Wrapping text", row)
        local line_start = 1
        local previous_word_end = -1
        while true do
            while line_start <= #row and string.sub(row, line_start, line_start) == ' ' do
                line_start = line_start + 1
            end
            if line_start > #row then return out end
            local line_end = line_start
            local line = string.sub(row, line_start, line_end)
            while line_end <= #row and width_of(line) <= width do
                line_end = line_end + 1
                line = string.sub(row, line_start, line_end)
                if string.sub(row, line_end, line_end) == ' ' and string.sub(row, line_end - 1, line_end - 1) ~= ' ' then
                    previous_word_end = line_end - 1
                end
            end

            if line_end > #row and width_of(line) <= width then
                table.insert(out, line)
                log.trace("Wrapping finished! " .. #out .. " rows.")
                return out
            elseif previous_word_end >= line_start then
                local sub_row = string.sub(row, line_start, previous_word_end)
                log.trace("Wrapping", sub_row)
                table.insert(out, sub_row)
                line_start = previous_word_end + 1
            else
                local sub_row = string.sub(row, line_start, line_end - 2)
                log.trace("Hyphenating", sub_row)
                table.insert(out, sub_row .. '-')
                line_start = line_end - 1
            end
        end
    else
        unexpected(self.wrap)
        return {}
    end
end

--- Update the draw area width, invalidating cached wrapping when the width changes.
---@param w integer
function TextImpl:set_width(w)
    if self.width ~= w then
        for _, l in ipairs(self.lines) do
            l.wrapped_lines = nil
        end
    end
    self.width = w
end

--- Update the draw area height.
---@param h integer
function TextImpl:set_height(h)
    self.height = h
end

--- Replace the paragraph strings, preserving cached wrapping for unchanged lines.
---@param lines string[] New paragraph strings.
function TextImpl:set_lines(lines)
    if #lines ~= #self.lines then
        self.lines = text_lines(lines)
    else
        for i, l in ipairs(lines) do
            if self.lines[i].text ~= l then
                self.lines[i].text = l
                self.lines[i].wrapped_lines = nil
            end
        end
    end
end

--- Return the total number of display rows after all paragraphs are wrapped.
---@return integer Total wrapped row count across all paragraphs.
function TextImpl:get_wrapped_rows()
    return lists.sum(function(l)
        if l.wrapped_lines == nil then
            l.wrapped_lines = self:apply_text_wrapping(l.text, self.width)
        end
        log.trace("wrapped lines", l.text, l.wrapped_lines)
        return #l.wrapped_lines
    end)(self.lines)
end

--- Return the wrapped sub-lines for each paragraph.
---@return string[][] For each paragraph, its list of wrapped display lines.
function TextImpl:get_lines()
    return lists.map(function(l)
        if l.wrapped_lines == nil then
            l.wrapped_lines = self:apply_text_wrapping(l.text, self.width)
        end
        return l.wrapped_lines
    end)(self.lines)
end

---@type table<Justify, fun(row: string, w: integer): integer>
local get_text_alignment_offset = {
    ["left"]   = function(_row, _w) return 0 end,
    ["center"] = function(row, w)
        local line_width = width_of(row)
        return (w - line_width) // 2
    end,
    ["right"]  = function(row, w)
        local line_width = width_of(row)
        return w - line_width - 1
    end,
}

---@param row string
---@param x integer
---@param y integer
---@param justify Justify
---@param color Color
---@param row_number integer 1-based display row index used to compute the y offset.
---@param line_count integer|nil Character limit for typewriter reveal; nil draws the full row.
function TextImpl:draw_justified_text_row(row, x, y, justify, color, row_number, line_count)
    local x_offset = get_text_alignment_offset[justify](row, self.width or 0)
    local t_x = x + x_offset
    local t_y = y + ((row_number - 1) * TEXT_ROW_HEIGHT)
    local out = row
    if line_count ~= nil then
        if line_count <= 0 then
            out = ""
        else
            out = string.sub(out, 1, line_count)
        end
    end
    pt.print(out, t_x, t_y, color)
end

---@param text_row string
---@param x integer
---@param y integer
---@param color Color
---@param row_number integer 1-based display row index.
---@param line_count integer|nil Character limit for typewriter reveal; nil draws the full row.
function TextImpl:draw_text_row(text_row, x, y, color, row_number, line_count)
    if self.align then
        -- split on "|"
        local subrows = {}
        local start = 1
        while true do
            local fs, fe = text_row:find("|", start, true)
            if not fs then
                table.insert(subrows, text_row:sub(start))
                break
            end
            table.insert(subrows, text_row:sub(start, fs - 1))
            start = fe + 1
        end

        if #subrows == 1 then
            self:draw_justified_text_row(subrows[1], x, y, self.justify, color, row_number, line_count)
        elseif #subrows == 2 then
            self:draw_justified_text_row(subrows[1], x, y, "left",  color, row_number, line_count)
            self:draw_justified_text_row(subrows[2], x, y, "right", color, row_number, line_count)
        elseif #subrows == 3 then
            self:draw_justified_text_row(subrows[1], x, y, "left",   color, row_number, line_count)
            self:draw_justified_text_row(subrows[3], x, y, "right",  color, row_number, line_count)
            self:draw_justified_text_row(subrows[2], x, y, "center", color, row_number, line_count)
        else
            error("Tried to align with more than 3 segments: " .. text_row)
        end
    else
        self:draw_justified_text_row(text_row, x, y, self.justify, color, row_number, line_count)
    end
end

--- Pre-compute and cache wrapped lines for every paragraph.
function TextImpl:calculate_wrapping()
    for _, paragraph in ipairs(self.lines) do
        if paragraph.wrapped_lines == nil then
            paragraph.wrapped_lines = self:apply_text_wrapping(paragraph.text, self.width)
        end
    end
end

--- Draw all paragraphs at (x, y) using the given color.
---@param x integer
---@param y integer
---@param color Color
---@param line_counts integer[]|nil Per-paragraph character limit for typewriter-style reveals; nil draws the full text.
function TextImpl:draw(x, y, color, line_counts)
    -- profile("draw_text")
    self:calculate_wrapping()
    local row_count = 0
    for i, paragraph in ipairs(self.lines) do
        local line_count = nil
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
    -- profile("draw_text")
end

--- Draw a single paragraph by 1-based index.
---@param row_number integer 1-based index of the paragraph to draw.
---@param x integer
---@param y integer
---@param color Color
---@param line_count integer|nil Character limit for typewriter reveal; nil draws the full paragraph.
function TextImpl:draw_one(row_number, x, y, color, line_count)
    -- profile("draw_text")
    self:calculate_wrapping()
    local row_count = 0
    local paragraph = self.lines[row_number]
    for _, text_row in ipairs(paragraph.wrapped_lines) do
        row_count = row_count + 1
        self:draw_text_row(text_row, x, y, color, row_count, line_count)
        if line_count ~= nil then
            line_count = line_count - #text_row
        end
    end
    -- profile("draw_text")
end

return text
