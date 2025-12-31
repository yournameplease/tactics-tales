local box = require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local text_node = require("src/tactics/ui/components/text_node")
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
local text = require("src/tactics/util/text")

local record MessageLog
    is box.UIElement, text_node.TextUIElement
    func: function(UIContextManager, integer): { string }
end
setmetatable(MessageLog, { __index = box.Box})

local message_log = {
    MessageLog = MessageLog
}

-- extra props
-- func(state, (opt)row_limit) = text callback
-- rows = defaults to 1
-- justify
function message_log.new(props: MessageLog): box.UIElement
    local self = box.new(props) as MessageLog
    setmetatable(self, { __index = MessageLog })

    self.padding = props.padding or 1
    self.decoration_padding = 0
    self.func = props.func or error("Need text getter `func`")

    self.draw_properties = props.draw_properties or {}
    self.draw_properties.justify = self.draw_properties.justify or "left"
    self.draw_properties.direction = self.draw_properties.direction or "up"
    self.draw_properties.wrap = self.draw_properties.wrap or "wrap"

    self.text_object = text.new(
        {},
        self.draw_properties,
        self.w,
        self.h
    )
    
    return self
end

function MessageLog:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    box.Box._draw(self, state, draw_target_manager, ui_theme)

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
