---@brief
--- A UI component for displaying dialogue text, with support for
--- revealing text character by character.

local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local box = require("src.tactics.ui.box")
local Dialogue = require("src.tactics.dialogue.dialogue").Dialogue

local dialogue_node = {}

function dialogue_node.multi_line(dialogue: Dialogue, text_info: box.text_info.TextInfo): box.UIElement
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.line_counts = {}
    text_info.content = dialogue.text

    return box.builder("multi_dialogue")
    :text(text_info)
    :on_update(function(self: box.UIElement, _state: UIContextManager)
        for i = 1,#dialogue.text do
            if i < dialogue.current_row then
                self.text.line_counts[i] = #dialogue.text[i]
            elseif i == dialogue.current_row then
                self.text.line_counts[i] = dialogue.characters_rendered
            end
        end
    end)
    :build()
end

function dialogue_node.single_line(dialogue: Dialogue, text_info: box.text_info.TextInfo): box.UIElement
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.line_counts = {}
    text_info.content = dialogue.text

    return box.builder("single_dialogue")
    :text(text_info)
    :on_update(function(self: box.UIElement, _state: UIContextManager)
        for i = 1,#dialogue.text do
            if i < dialogue.current_row then
                self.text.line_counts[i] = #dialogue.text[i]
            elseif i == dialogue.current_row then
                self.text.line_counts[i] = dialogue.characters_rendered
            end
        end
        self.text.drawn_line = dialogue.current_row
    end)
    :build()
end

return dialogue_node
