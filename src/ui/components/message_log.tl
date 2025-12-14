require("src/ui/box")
require("src/ui/components/text_node")
require("src/ui/ui_context_manager")
local Text = require("src/util/text")

global record MessageLog
    is UIElement, TextUIElement
    func: function(UIContextManager, integer): { string }
end 


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

    props.draw_properties = props.draw_properties or {}
    box.draw_properties = box.draw_properties or {
        justify = "left",
        text_direction = "up",
        wrap_mode = "wrap"
    }
    box.draw_properties.justify = props.draw_properties.justify or box.draw_properties.justify
    box.draw_properties.text_direction = props.draw_properties.text_direction or box.draw_properties.text_direction
    box.draw_properties.wrap_mode = box.draw_properties.wrap_mode

    return box
end

function MessageLog:draw(state: UIContextManager, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local text = self.func(state, 999)

    -- TODO: text wrapping?  and cutoff text if not wrap
    -- local rows_to_render = min(row_count, #text)
    -- for i=1,rows_to_render do
    --     draw_text_row(self, i, text[#text-i+1], ui_theme)
    -- end

    Text.draw(text,
        self.x+self.internal_margin.l,
        self.y+self.internal_margin.t,
        self.w-self.internal_margin.l-self.internal_margin.r,
        self.h-self.internal_margin.t-self.internal_margin.b,
        ui_theme.COLOR_INTERIOR_TEXT, self.draw_properties)
end

setmetatable(MessageLog, { __index = Box})

return MessageLog
