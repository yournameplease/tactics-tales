---@brief
--- A UI component for displaying dialogue text, with support for
--- revealing text character by character.

local box = require("src.tactics.ui.box")

local dialogue_node = {}

--- Build a multi-dialogue element that displays one or more dialogue lines.
---@param dialogue ActiveDialogue
---@param text_info TextInfoOptions
---@return UIElement
function dialogue_node.multi_line(dialogue, text_info)
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.line_counts = {}
    text_info.content = dialogue.text

    return box.builder("multi_dialogue")
        :padding(1)
        :text(text_info)
        :on_update(function(self, _state)
            self.text.content = dialogue.text
            for i = 1, #dialogue.text do
                if i < dialogue.current_row then
                    self.text.line_counts[i] = #dialogue.text[i]
                elseif i == dialogue.current_row then
                    self.text.line_counts[i] = dialogue.characters_rendered
                end
            end
        end)
        :build()
end

--- Build a dialogue element that reveals one dialogue line at a time.
---@param dialogue ActiveDialogue
---@param text_info TextInfoOptions
---@return UIElement
function dialogue_node.single_line(dialogue, text_info)
    text_info.draw_properties = text_info.draw_properties or {}
    text_info.draw_properties.justify = text_info.draw_properties.justify or "center"
    text_info.line_counts = {}
    text_info.content = dialogue.text

    return box.builder("single_dialogue")
        :padding(1)
        :text(text_info)
        :on_update(function(self, _state)
            self.text.content = dialogue.text
            for i = 1, #dialogue.text do
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
