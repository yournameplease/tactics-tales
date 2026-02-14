---@brief
--- A general-purpose UI component for rendering text with
--- various layout and wrapping options.

local box = require("src.tactics.ui.box")
local section_divider = require("src.tactics.ui.decoration.book").section_divider

local text_node = {}

function text_node.title(text_info: box.text_info.TextInfo): box.UIElement
    box.builder("title")

    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"

    local self = box.builder("title_box")
    :layout(box.layout.col_fit())
    :build()
    :add(
        box.builder("text")
        :text(text_info)
        :build()
    )
    :add(
        section_divider(2)
    )
    return self
end

return text_node
