require("src/ui/box")
require("src/ui/panels/text_node")

global record MessageLog
    is UIElement, TextUIElement
    func: function(GameContext, integer): { string }
end 

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

-- extra props
-- func(state, (opt)row_limit) = text callback
-- rows = defaults to 1
-- justify
function MessageLog.new(props: MessageLog): MessageLog
    local box = Box.new(props) as MessageLog
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

function MessageLog:draw(state: GameContext, ui_theme: UITheme)
    self:draw(state, ui_theme)

    local row_count = self.rows or flr(self.h / TEXT_ROW_HEIGHT)

    local text = self.func(state, row_count)

    -- TODO: text wrapping?  and cutoff text if not wrap
    local rows_to_render = min(row_count, #text)
    for i=1,rows_to_render do
        draw_text_row(self, i, text[#text-i+1], ui_theme)
    end

end

setmetatable(MessageLog, { __index = Box})

return MessageLog
