
---@brief
--- A UI component for displaying dialogue text, with support for
--- revealing text character by character.

local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local box = require("src.tactics.ui.box")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local text = require("src.tactics.util.text")
local lists = require("src.tactics.util.lists")
local Dialogue = require("src.tactics.dialogue.dialogue").Dialogue

local enum UITextColor
    "dark"
    "trim"
    "strong"
    "light"
end

local interface TextUIElement
    is box.UIElement
    draw_properties: text.DrawProperties
    text_color: UITextColor

    text_object: text.Text

    get_hovered_line: function(self, lx: number, ly: number): integer
end

local enum DialogueMode
    "all_lines"
    "active_line"
end

local record DialogueNode
    is box.UIElement, TextUIElement
    dialogue: Dialogue
    dialogue_mode: DialogueMode
    rows: integer
end

setmetatable(DialogueNode, { __index = box.Box })

local TEXT_HEIGHT = 8
local TEXT_ROW_HEIGHT = TEXT_HEIGHT + 2

function DialogueNode:compute_children(_: UIContextManager)
    -- compute text as a "child", so it may be measured
    -- in the same frame
    local lines = self.dialogue and self.dialogue.text

    if self.rows then
        assert(
                #lines ==
                self.rows, "`func` should return expected number of rows"
        )
    end

    local text_obj = self.text_object
    text_obj:set_width(self.w-self.internal_margin.l-self.internal_margin.r)
    text_obj:set_height(self.h-self.internal_margin.t-self.internal_margin.b)
    text_obj:set_lines(lines)
    text_obj:calculate_wrapping()
end

function DialogueNode:measure(depth: integer)
    local text_obj = self.text_object
    if text_obj ~= nil then
        self.text_object:calculate_wrapping()
    end
    box.Box._measure(self, depth)

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

function DialogueNode:get_hovered_line(_lx: number, ly: number): integer
    local paragraph_heights = lists.map(
        function(p: {string}): integer return #p end
    )(self.text_object:get_lines())

    local line_count = 0
    local i = 0
    while ly > line_count * TEXT_ROW_HEIGHT and i < #paragraph_heights do
        i = i + 1
        line_count = line_count + paragraph_heights[i]
    end
    return i
end

function DialogueNode:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    box.Box._draw(self, state, draw_target_manager, ui_theme)

    local colors <total>: {UITextColor: Color} = {
        dark = ui_theme.COLOR_INTERIOR_TEXT,
        trim = ui_theme.COLOR_TRIM,
        strong = ui_theme.COLOR_PAGE_DECOR,
        light = ui_theme.COLOR_DECORATION_SHADOW,
    }


    local text_obj = self.text_object
	if self.dialogue_mode == "all_lines" then
	    local line_counts: {integer} = {}
        for i = 1,#self.dialogue.text do
            local line_count = 0
            if i < self.dialogue.current_row then
                line_count = #self.dialogue.text[i]
            elseif i == self.dialogue.current_row then
                line_count = self.dialogue.characters_rendered
            end
        
            pt.add(line_counts, line_count) 
	    end
	    text_obj:draw(
	        self.x+self.internal_margin.l,
	        self.y+self.internal_margin.t,
	        colors[self.text_color],
	        line_counts
	    )
	else
	    text_obj:draw_one(
			self.dialogue.current_row,
	        self.x+self.internal_margin.l,
	        self.y+self.internal_margin.t,
	        colors[self.text_color],
	        self.dialogue.characters_rendered
	    )
	end
end

local dialogue_node = {
    DialogueNode = DialogueNode,
}

function dialogue_node.new(props: DialogueNode): DialogueNode
    local self = box.new(props) as DialogueNode
    setmetatable(self, { __index = DialogueNode })

    self.padding = props.padding or 0
    self.decoration_padding = 0
    self.dialogue = props.dialogue
    self.dialogue_mode = props.dialogue_mode or "all_lines"
    if props.rows then
        self.rows = props.rows
        self.h = (self.rows) * (TEXT_HEIGHT + 2)
    end

    self.draw_properties = props.draw_properties or {}
    self.draw_properties.justify = self.draw_properties.justify or "left"
    self.draw_properties.direction = self.draw_properties.direction or "down"
    self.draw_properties.align = self.draw_properties.align or false
    self.draw_properties.wrap = self.draw_properties.wrap or
        (self.draw_properties.align and "no_wrap" or "ellipsis")

    if props.auto_width and self.draw_properties.wrap ~= "no_wrap" then
        error("auto_width must use no_wrap")
    end
    
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

return dialogue_node
