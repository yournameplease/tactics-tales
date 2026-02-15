---@brief
--- A general-purpose UI component for rendering text with
--- various layout and wrapping options.

local box = require("src.tactics.ui.box")
local book = require("src.tactics.ui.decoration.book")

local text_node = {}

function text_node.title(text_info: box.text_info.TextInfo): box.UIElement
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.draw_properties.wrap = "no_wrap"
    text_info.rows = 1

    local self = box.builder("title_box")
		:direction("col")
		:container("block")
        :build()

    self:add(
        box.builder("text")
        :text(text_info)
        :build()
    )
    self:add(
        book.section_divider(2)
    )
    return self
end

return text_node
