Box = require("src/ui/box.lua")

local MessageLog = {}

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

-- extra props
-- func(state, (opt)row_limit) = text callback
-- rows = defaults to 1
-- justify
function MessageLog.new(props)
    local box = Box.new(props)
    setmetatable(box, { __index = MessageLog })

    box.padding = props.padding or 1
    box.decoration_padding = 0
    box.func = props.func or error("Need text getter `func`")
    if not box.auto_height then
        if props.rows then
            box.rows = props.rows or 1
            box.h = (box.rows) * (TEXT_HEIGHT + 2)
        elseif box.h then
        --    ok
        else
            error("Need height for MessageLog")
        end
    end
    box.justify = props.justify or "left"  -- "left", "right", "center"

    return box
end

local function draw_text_row(self, i, text)
    local text_width = print(text, 0, -1000)

    local t_x
    if self.justify == "left" then
        t_x = self.x + self.padding + 1
    elseif self.justify == "center" then
        t_x = self.x + (self.w - 2 * (self.padding + 1) - text_width) / 2
    elseif self.justify == "right" then
        t_x = self.x + self.w - self.padding - 1 - text_width - 1
    else
        error("Unexpected value!")
    end

    print(text, t_x, self.y + self.padding + 1 + ((i-1) * TEXT_ROW_HEIGHT), UI_MANAGER.THEME.COLOR_INTERIOR_TEXT)
end

function MessageLog:draw(state)
    Box.draw(self, state)

    local row_count = self.rows or flr(self.h / TEXT_ROW_HEIGHT)

    local text = self.func(state, row_count)

    -- TODO: text wrapping?  and cutoff text if not wrap
    local rows_to_render = min(row_count, #text)
    for i=1,rows_to_render do
        draw_text_row(self, i, text[#text-i+1])
    end

end

setmetatable(MessageLog, { __index = Box})

return MessageLog
