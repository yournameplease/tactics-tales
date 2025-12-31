require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local text_node = require("src/tactics/ui/components/text_node")
require("src/tactics/ui/ui_context_manager")
local text = require("src/tactics/util/text")

local record MessageLog
    is UIElement, text_node.TextUIElement
    func: function(UIContextManager, integer): { string }
end
setmetatable(MessageLog, { __index = Box})

local message_log = {
    MessageLog = MessageLog
}

-- extra props
-- func(state, (opt)row_limit) = text callback
-- rows = defaults to 1
-- justify
function message_log.new(props: MessageLog): UIElement
    local box = Box.new(props) as MessageLog
    setmetatable(box, { __index = MessageLog })

    box.padding = props.padding or 1
    box.decoration_padding = 0
    box.func = props.func or error("Need text getter `func`")

    box.draw_properties = props.draw_properties or {}
    box.draw_properties.justify = box.draw_properties.justify or "left"
    box.draw_properties.direction = box.draw_properties.direction or "up"
    box.draw_properties.wrap = box.draw_properties.wrap or "wrap"

    box.text_object = text.new(
        {},
        box.draw_properties,
        box.w,
        box.h
    )
    
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

    local text_obj = self.text_object

    text_obj:set_width(self.w-self.internal_margin.l-self.internal_margin.r)
    text_obj:set_height(self.h-self.internal_margin.t-self.internal_margin.b)
    text_obj:set_lines(lines)
    text_obj:draw(
        self.x+self.internal_margin.l,
        self.y+self.internal_margin.t,
        ui_theme.COLOR_INTERIOR_TEXT
    )
end

return message_log
