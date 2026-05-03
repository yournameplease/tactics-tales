---@brief
--- Represents the current visible state of a campaign scene.
--- It holds the collection of nodes (text, menus) to be rendered.

local character = require("src.tactics.character.object.character")

---@alias RenderedCampaignNodeType "text"|"character_customization"|"text_input"|"chapter_header"|"game_results"|"select_option"

---@class RenderedCampaignNode Abstract base for all rendered campaign nodes.
---@field type RenderedCampaignNodeType

---@class RenderedText : RenderedCampaignNode Rendered dialogue line.
---@field type "text"
---@field text ActiveDialogue

---@class RenderedCharacterCustomization : RenderedCampaignNode Character appearance editor shown in-campaign.
---@field type "character_customization"
---@field key string Memory key for the character slot.
---@field character DrawableCharacter

---@alias GameResultsSection "chapters"|"units"

---@class RenderedGameResults : RenderedCampaignNode End-of-game results display.
---@field type "game_results"
---@field section GameResultsSection Which section of results is being displayed.
---@field page integer Current page index within the section.
---@field results CampaignResults
---@field chapter_pages GameResultsChapterDisplay[]
---@field unit_pages GameResultsUnitDisplay[]

---@class RenderedTextInput : RenderedCampaignNode Player text-entry prompt.
---@field type "text_input"
---@field key string Memory key where the entered text will be stored.
---@field text? ActiveDialogue Prompt shown above the input; set only when constructed via add_text_input_menu.

---@class RenderedSelectOption : RenderedCampaignNode Option picker menu.
---@field type "select_option"
---@field options SelectOptionEntry[] Options to display.

---@class RenderedChapterHeader : RenderedCampaignNode Chapter title card.
---@field type "chapter_header"
---@field text string Chapter title text.
---@field number integer Chapter number.

local rendered_campaign_node = {}

--- Create a chapter header node.
---@param text string Chapter title text.
---@param number integer Chapter number.
---@return RenderedCampaignNode
function rendered_campaign_node.chapter_header(text, number)
    ---@type RenderedChapterHeader
    local node = {
        type = 'chapter_header',
        text = text,
        number = number,
    }
    return node
end

--- Create a game results node showing the first page of chapter results.
---@param results CampaignResults
---@param chapter_pages GameResultsChapterDisplay[]
---@param unit_pages GameResultsUnitDisplay[]
---@return RenderedCampaignNode
function rendered_campaign_node.game_results(results, chapter_pages, unit_pages)
    ---@type RenderedGameResults
    local node = {
        type = 'game_results',
        section = 'chapters',
        page = 1,
        results = results,
        chapter_pages = chapter_pages,
        unit_pages = unit_pages,
    }
    return node
end

--- Create a text node wrapping a dialogue.
---@param text ActiveDialogue
---@return RenderedCampaignNode
function rendered_campaign_node.text(text)
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
---@return RenderedCampaignNode
function rendered_campaign_node.character_customization(base_character, key, anim)
    ---@type RenderedCharacterCustomization
    local node = {
        type = 'character_customization',
        key = key,
        character = character.create_drawable_unit(
            base_character,
            "player",
            character.facing.of("left")
        ),
    }
    node.character.animation_data = anim
    return node
end

--- Create a select option node for presenting a list of choices.
---@param options SelectOptionEntry[]
---@return RenderedCampaignNode
function rendered_campaign_node.select_option(options)
    ---@type RenderedSelectOption
    local node = {
        type = 'select_option',
        options = options,
    }
    return node
end

--- Create a text input node for collecting player input.
---@param key string Memory key where the entered text will be stored.
---@return RenderedCampaignNode
function rendered_campaign_node.text_input(key)
    ---@type RenderedTextInput
    local node = {
        type = 'text_input',
        key = key,
    }
    return node
end

---@class CampaignPage The current campaign scene state.
---@field nodes RenderedCampaignNode[] Ordered list of nodes currently visible on the page.
---@field chapter_text string Title text of the current chapter, set after clearing the header node.
---@field chapter_number integer Number of the current chapter, set after clearing the header node.
---@field campaign_revision integer Incremented each time the page content changes.
---@field campaign_state CampaignState
local CampaignPage = {}
CampaignPage.__index = CampaignPage

local campaign_page = {
    rendered_campaign_node = rendered_campaign_node,
}

--- Create a new CampaignPage backed by the given campaign memory.
---@param campaign_mem CampaignState
---@return CampaignPage
function campaign_page.new(campaign_mem)
    local self = setmetatable({
        campaign_state = campaign_mem,
        campaign_revision = 0,
        nodes = {},
    }, CampaignPage)
    return self
end

--- Append a chapter header node to the page.
---@param text string Chapter title text.
---@param number integer Chapter number.
function CampaignPage:add_chapter_header(text, number)
    local node = rendered_campaign_node.chapter_header(text, number)
    table.insert(self.nodes, node)
end

-- TODO: move all these constructors out of here,
-- back in to campaign class?
--- Remove the topmost node (expected to be a chapter header) and store its values in chapter_text / chapter_number.
function CampaignPage:clear_chapter_header()
    local chapter_header_node = self.nodes[#self.nodes]
    ---@cast chapter_header_node RenderedChapterHeader
    self.chapter_text = chapter_header_node.text
    self.chapter_number = chapter_header_node.number
    table.remove(self.nodes)
end

--- Remove the topmost node from the page.
function CampaignPage:pop()
    table.remove(self.nodes)
end

--- Mark the topmost text node as fully rendered (all characters visible).
function CampaignPage:finish_text()
    local text_node = self.nodes[#self.nodes]
    ---@cast text_node RenderedText
    text_node.text.characters_rendered = #text_node.text.text
end

--- Append a text node for the given dialogue.
---@param dialogue ActiveDialogue
function CampaignPage:add_text_line(dialogue)
    local node = rendered_campaign_node.text(dialogue)
    table.insert(self.nodes, node)
end

--- Append a character customization node.
---@param base_character Character Source character whose stats and appearance are used.
---@param key string Memory key for this character slot.
---@param anim AnimatedSpriteData Animation data to display for the character.
function CampaignPage:add_character_customization_menu(base_character, key, anim)
    local node = rendered_campaign_node.character_customization(base_character, key, anim)
    table.insert(self.nodes, node)
end

--- Append a game results node with pre-built display data.
---@param results CampaignResults
---@param chapter_pages GameResultsChapterDisplay[]
---@param unit_pages GameResultsUnitDisplay[]
function CampaignPage:add_game_results(results, chapter_pages, unit_pages)
    local node = rendered_campaign_node.game_results(results, chapter_pages, unit_pages)
    table.insert(self.nodes, node)
end

--- Append a select option node.
---@param options SelectOptionEntry[]
function CampaignPage:add_select_option_menu(options)
    local node = rendered_campaign_node.select_option(options)
    table.insert(self.nodes, node)
end

--- Append a prompt text node followed by a text input node.
---@param key string Memory key where the entered text will be stored.
---@param text ActiveDialogue Prompt dialogue shown above the input field.
function CampaignPage:add_text_input_menu(key, text)
    local text_node = rendered_campaign_node.text(text)
    local input_node = rendered_campaign_node.text_input(key)
    table.insert(self.nodes, text_node)
    table.insert(self.nodes, input_node)
end

--- Remove all nodes from the page.
function CampaignPage:clear_page()
    self.nodes = {}
end

return campaign_page
