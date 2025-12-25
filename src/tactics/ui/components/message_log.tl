require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/ui_context_manager")
local text = require("src/tactics/util/text")

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

    box.draw_properties = props.draw_properties or {}
    box.draw_properties.justify = box.draw_properties.justify or "left"
    box.draw_properties.direction = box.draw_properties.direction or "up"
    box.draw_properties.wrap = box.draw_properties.wrap or "wrap"

    return box
end

function MessageLog:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    Box._draw(self, state, draw_target_manager, ui_theme)

    local row_limit = (self.h-self.internal_margin.t-self.internal_margin.b) // 10

    local lines = self.func(state, row_limit)

    -- TODO: text wrapping?  and cutoff text if not wrap
    -- local rows_to_render = pt.min(row_count, #text)
    -- for i=1,rows_to_render do
    --     draw_text_row(self, i, text[#text-i+1], ui_theme)
    -- end

    local text_obj = text.new(lines, self.draw_properties)
    
    text_obj:draw(
        self.x+self.internal_margin.l,
        self.y+self.internal_margin.t,
        self.w-self.internal_margin.l-self.internal_margin.r,
        self.h-self.internal_margin.t-self.internal_margin.b,
        ui_theme.COLOR_INTERIOR_TEXT
    )
end

setmetatable(MessageLog, { __index = Box})

return MessageLog
