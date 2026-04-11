---@brief
--- Represents the current visible state of a story scene.
--- It holds the collection of nodes (text, menus) to be rendered.

local drawable_character = require("src.tactics.story.drawable_character")
local character = require("src.tactics.character.object.character")

---@alias RenderedStoryNodeType "text"|"character_customization"|"text_input"|"chapter_header"|"game_results"

---@class RenderedStoryNode Abstract base for all rendered story nodes.
---@field type RenderedStoryNodeType

---@class RenderedText : RenderedStoryNode Rendered dialogue line.
---@field type "text"
---@field text ActiveDialogue

---@class RenderedCharacterCustomization : RenderedStoryNode Character appearance editor shown in-story.
---@field type "character_customization"
---@field key string Memory key for the character slot.
---@field character DrawableCharacter

---@alias GameResultsSection "chapters"|"units"

---@class RenderedGameResults : RenderedStoryNode End-of-game results display.
---@field type "game_results"
---@field section GameResultsSection Which section of results is being displayed.
---@field page integer Current page index within the section.
---@field results StoryResults

---@class RenderedTextInput : RenderedStoryNode Player text-entry prompt.
---@field type "text_input"
---@field key string Memory key where the entered text will be stored.
---@field text? ActiveDialogue Prompt shown above the input; set only when constructed via add_text_input_menu.

---@class RenderedChapterHeader : RenderedStoryNode Chapter title card.
---@field type "chapter_header"
---@field text string Chapter title text.
---@field number integer Chapter number.

local rendered_story_node = {}

--- Create a chapter header node.
---@param text string Chapter title text.
---@param number integer Chapter number.
---@return RenderedStoryNode
function rendered_story_node.chapter_header(text, number)
    ---@type RenderedChapterHeader
    local node = {
        type = 'chapter_header',
        text = text,
        number = number,
    }
    return node
end

--- Create a game results node showing the first page of chapter results.
---@param results StoryResults
---@return RenderedStoryNode
function rendered_story_node.game_results(results)
    ---@type RenderedGameResults
    local node = {
        type = 'game_results',
        section = 'chapters',
        page = 1,
        results = results,
    }
    return node
end

--- Create a text node wrapping a dialogue.
---@param text ActiveDialogue
---@return RenderedStoryNode
function rendered_story_node.text(text)
    ---@type RenderedText
    local node = {
        type = 'text',
        text = text,
    }
    return node
end

--- Create a character customization node for the given character slot.
---@param base_character Character Source character whose stats and appearance are used.
---@param key string Memory key for this character slot.
---@param anim AnimatedSpriteData Animation data to display for the character.
---@return RenderedStoryNode
function rendered_story_node.character_customization(base_character, key, anim)
    ---@type RenderedCharacterCustomization
    local node = {
        type = 'character_customization',
        key = key,
        character = drawable_character.create_drawable_unit(
            base_character,
            "player",
            character.facing.of("left")
        ),
    }
    node.character.animation_data = anim
    return node
end

--- Create a text input node for collecting player input.
---@param key string Memory key where the entered text will be stored.
---@return RenderedStoryNode
function rendered_story_node.text_input(key)
    ---@type RenderedTextInput
    local node = {
        type = 'text_input',
        key = key,
    }
    return node
end

---@class StoryPage The current story scene state.
---@field package nodes RenderedStoryNode[] Ordered list of nodes currently visible on the page.
---@field package chapter_text string Title text of the current chapter, set after clearing the header node.
---@field package chapter_number integer Number of the current chapter, set after clearing the header node.
---@field package story_revision integer Incremented each time the page content changes.
---@field package story_memory StoryMemory
local StoryPage = {}
StoryPage.__index = StoryPage

local story_page = {
    rendered_story_node = rendered_story_node,
}

--- Create a new StoryPage backed by the given story memory.
---@param story_mem StoryMemory
---@return StoryPage
function story_page.story_page(story_mem)
    local self = setmetatable({
        story_memory = story_mem,
        story_revision = 0,
        nodes = {},
    }, StoryPage)
    return self
end

--- Append a chapter header node to the page.
---@param text string Chapter title text.
---@param number integer Chapter number.
function StoryPage:add_chapter_header(text, number)
    local node = rendered_story_node.chapter_header(text, number)
    table.insert(self.nodes, node)
end

-- TODO: move all these constructors out of here,
-- back in to story class?
--- Remove the topmost node (expected to be a chapter header) and store its values in chapter_text / chapter_number.
function StoryPage:clear_chapter_header()
    local chapter_header_node = self.nodes[#self.nodes] ---@type RenderedChapterHeader
    self.chapter_text = chapter_header_node.text
    self.chapter_number = chapter_header_node.number
    table.remove(self.nodes)
end

--- Remove the topmost node from the page.
function StoryPage:pop()
    table.remove(self.nodes)
end

--- Mark the topmost text node as fully rendered (all characters visible).
function StoryPage:finish_text()
    local text_node = self.nodes[#self.nodes] ---@type RenderedText
    text_node.text.characters_rendered = #text_node.text.text
end

--- Append a text node for the given dialogue.
---@param dialogue ActiveDialogue
function StoryPage:add_text_line(dialogue)
    local node = rendered_story_node.text(dialogue)
    table.insert(self.nodes, node)
end

--- Append a character customization node.
---@param base_character Character Source character whose stats and appearance are used.
---@param key string Memory key for this character slot.
---@param anim AnimatedSpriteData Animation data to display for the character.
function StoryPage:add_character_customization_menu(base_character, key, anim)
    local node = rendered_story_node.character_customization(base_character, key, anim)
    table.insert(self.nodes, node)
end

--- Append a game results node.
---@param results StoryResults
function StoryPage:add_game_results(results)
    local node = rendered_story_node.game_results(results)
    table.insert(self.nodes, node)
end

--- Append a prompt text node followed by a text input node.
---@param key string Memory key where the entered text will be stored.
---@param text ActiveDialogue Prompt dialogue shown above the input field.
function StoryPage:add_text_input_menu(key, text)
    local text_node = rendered_story_node.text(text)
    local input_node = rendered_story_node.text_input(key)
    table.insert(self.nodes, text_node)
    table.insert(self.nodes, input_node)
end

--- Remove all nodes from the page.
function StoryPage:clear_page()
    self.nodes = {}
end

return story_page
