require("src/tactics/ui/ui_context_manager")
require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local text = require("src/tactics/util/text")
local section_divider = require("src/tactics/ui/decoration/section_divider")

global enum UITextColor
    "dark"
    "trim"
    "light"
end

global interface TextUIElement
    is UIElement
    draw_properties: text.DrawProperties
    text_color: UITextColor

    text_object: text.Text
end


global record TextNode
    is UIElement, TextUIElement
    func: function(UIContextManager): { string }
    text: { string }
    rows: integer

    _calculated_h: integer
end

setmetatable(TextNode, { __index = Box })

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

function TextNode:measure()
    Box._measure(self)

    local text_obj = self.text_object
    
    if self.auto_height and text_obj ~= nil then
        local rows = text_obj:get_wrapped_rows()
        self.h = rows * TEXT_ROW_HEIGHT + self.internal_margin.t + self.internal_margin.b
        self._calculated_h = self.h
    end
end

function TextNode:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    Box._draw(self, state, draw_target_manager, ui_theme)

    local lines = self.text or self.func(state)

    if self.rows then
        assert(
                #lines ==
                self.rows, "`func` should return expected number of rows"
        )
    end

    local colors <total>: {UITextColor: Color} = {
        dark = ui_theme.COLOR_INTERIOR_TEXT,
        trim = ui_theme.COLOR_TRIM,
        light = ui_theme.COLOR_DECORATION_SHADOW,
    }

    local text_obj = self.text_object

    text_obj:set_width(self.w-self.internal_margin.l-self.internal_margin.r)
    text_obj:set_height(self.h-self.internal_margin.t-self.internal_margin.b)
    text_obj:set_lines(lines)
    text_obj:draw(
        self.x+self.internal_margin.l,
        self.y+self.internal_margin.t,
        colors[self.text_color]
    )
end

local text_node = {}

function text_node.new(props: TextNode): TextNode
    local box = Box.new(props) as TextNode
    setmetatable(box, { __index = TextNode })

    box.padding = props.padding or 0
    box.decoration_padding = 0
    if props.text then
        box.text = props.text
    elseif props.func then
        box.func = props.func
    else
        error("Need either `text` or `func` for text node!")
    end
    if props.rows then
        box.rows = props.rows
        box.h = (box.rows) * (TEXT_HEIGHT + 2)
    end

    box.draw_properties = props.draw_properties or {}
    box.draw_properties.justify = box.draw_properties.justify or "left"
    box.draw_properties.direction = box.draw_properties.direction or "down"
    box.draw_properties.wrap = box.draw_properties.wrap or "ellipsis"

    box.transparent = props.transparent ~= false
    box.text_color = props.text_color or "dark"

    box.text_object = text.new(
        {},
        box.draw_properties,
        box.w,
        box.h
    )
    
    return box
end

function text_node.title(props: TextNode): UIElement
    props.auto_height = props.auto_height or true
    props.draw_properties = props.draw_properties or {}
    props.draw_properties.justify = props.draw_properties.justify or "center"

    local box = Box.col()
    box:add(text_node.new(props))
    box:add(section_divider.new(2))
    return box
end

return text_node
