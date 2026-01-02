local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
local box = require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local text = require("src/tactics/util/text")
local section_divider = require("src/tactics/ui/decoration/section_divider")
local MenuMouseSelection = require("src/tactics/menu/menu_cursor").mouse_selection.MenuMouseSelection

local enum UITextColor
    "dark"
    "trim"
    "light"
end

local interface TextUIElement
    is box.UIElement
    draw_properties: text.DrawProperties
    text_color: UITextColor

    text_object: text.Text

    get_hovered_line: function(self, lx: number, ly: number): integer
end


local record TextNode
    is box.UIElement, TextUIElement
    func: function(UIContextManager): { string }
    text: { string }
    rows: integer
end

setmetatable(TextNode, { __index = box.Box })

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

function TextNode:measure()
    local text_obj = self.text_object
    if text_obj ~= nil then
        self.text_object:calculate_wrapping()
    end
    box.Box._measure(self)

    if self.auto_height and text_obj ~= nil then
        local rows = text_obj:get_wrapped_rows()
        self.h = rows * TEXT_ROW_HEIGHT + self.internal_margin.t + self.internal_margin.b
        self.calculated_h = self.h
    end
    if self.auto_width and text_obj ~= nil then
        self.w = 40
        -- local rows = text_obj:get_wrapped_rows()
        -- self.h = rows * TEXT_ROW_HEIGHT + self.internal_margin.t + self.internal_margin.b
        self.calculated_w = self.w
    end
end

function TextNode:get_hovered_line(lx: number, ly: number): integer
    return 1
end

function TextNode:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    box.Box._draw(self, state, draw_target_manager, ui_theme)

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

local text_node = {
    TextNode = TextNode,
    TextUIElement = TextUIElement,
}

function text_node.new(props: TextNode): TextNode
    local self = box.new(props) as TextNode
    setmetatable(self, { __index = TextNode })

    self.padding = props.padding or 0
    self.decoration_padding = 0
    if props.text then
        self.text = props.text
    elseif props.func then
        self.func = props.func
    else
        error("Need either `text` or `func` for text node!")
    end
    if props.rows then
        self.rows = props.rows
        self.h = (self.rows) * (TEXT_HEIGHT + 2)
    end

    self.draw_properties = props.draw_properties or {}
    self.draw_properties.justify = self.draw_properties.justify or "left"
    self.draw_properties.direction = self.draw_properties.direction or "down"
    self.draw_properties.wrap = self.draw_properties.wrap or "ellipsis"

    self.transparent = props.transparent ~= false
    self.text_color = props.text_color or "dark"

    self.text_object = text.new(
        {},
        self.draw_properties,
        self.w,
        self.h
    )
    
    return self
end

function text_node.title(props: TextNode): box.UIElement
    props.auto_height = props.auto_height or true
    props.draw_properties = props.draw_properties or {}
    props.draw_properties.justify = props.draw_properties.justify or "center"

    local self = box.col()
    self:add(text_node.new(props))
    self:add(section_divider.new(2))
    return self
end

return text_node
