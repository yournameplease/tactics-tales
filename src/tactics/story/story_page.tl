---@brief
--- Represents the current visible state of a story scene.
--- It holds the collection of nodes (text, menus) to be rendered.

local animation = require("src.tactics.animation")
local drawable_character = require("src.tactics.story.drawable_character")
local story_memory = require("src.tactics.story.story_memory")
local Character = require("src.tactics.character.object.character").Character
local Dialogue = require("src.tactics.dialogue.dialogue").Dialogue

local enum RenderedStoryNodeType
    "text"
    "character_customization"
    "text_input"
    "chapter_header"
end

local interface RenderedStoryNode
    type: RenderedStoryNodeType
end

local record Text
    is RenderedStoryNode
    where self.type == "text"
    text: Dialogue
end

local record CharacterCustomization
    is RenderedStoryNode
    where self.type == "character_customization"
    key: string
    character: drawable_character.DrawableCharacter
end

local record TextInput
    is RenderedStoryNode
    where self.type == "text_input"
    key: string
    text: Dialogue
end

local record ChapterHeader
    is RenderedStoryNode
    where self.type == "chapter_header"
    text: string
    number: integer
end

local rendered_story_node = {
    RenderedStoryNode = RenderedStoryNode,
    Text = Text,
    TextInput = TextInput,
    ChapterHeader = ChapterHeader,
    CharacterCustomization = CharacterCustomization,
}

function rendered_story_node.chapter_header(text: string, number: integer): RenderedStoryNode
    local node: ChapterHeader = {
        type = 'chapter_header',
        text = text,
        number = number,
    }
    return node
end

function rendered_story_node.text(text: Dialogue): RenderedStoryNode
    local node: Text = {
        type = 'text',
        text = text,
    }
    return node
end

function rendered_story_node.character_customization(
    base_character: Character,
    key: string,
    anim: animation.AnimatedSpriteData
): RenderedStoryNode
    local node: rendered_story_node.CharacterCustomization = {
        type = 'character_customization',
    }

    node.key = key
    node.character = drawable_character.create_drawable_unit(
        base_character,
        "player",
        { vertical = "down", horizontal = "left" }
    )
    node.character.animation_data = anim
    return node
end

function rendered_story_node.text_input(
    key: string
): RenderedStoryNode
    local node: TextInput = {
        type = 'text_input',
        key = key,
    }
    return node
end

local interface StoryPage
    nodes: {RenderedStoryNode}
    chapter_text: string
    chapter_number: integer
    
    add_chapter_header: function(self, text: string, number: integer)
    clear_chapter_header: function(self)
    pop: function(self)
    finish_text: function(self)
    add_text_line: function(self, dialogue: Dialogue)
    add_text_input_menu: function(self, key: string, dialogue: Dialogue)
    add_character_customization_menu: function(self, base_character: Character, key: string, anim: animation.AnimatedSpriteData)
    clear_page: function(self)
    story_revision: integer
end

local story_page = {
    rendered_story_node = rendered_story_node,
    StoryPage = StoryPage,
}

local record StoryPageImpl
    is StoryPage
    story_memory: story_memory.StoryMemory
end

function story_page.story_page(
    story_mem: story_memory.StoryMemory
): StoryPage
    local self: StoryPageImpl = setmetatable({
        story_memory = story_mem,
        story_revision = 0,
    }, { __index = StoryPageImpl })
    self.nodes = {}
    return self
end

-- data access

function StoryPageImpl:add_chapter_header(text: string, number: integer)
    local node = rendered_story_node.chapter_header(text, number)
    pt.add(self.nodes, node)
end

-- TODO: move all these constructors out of here,
-- back in to story class?
function StoryPageImpl:clear_chapter_header()
    local chapter_header_node = self.nodes[#self.nodes]
    assert(chapter_header_node is ChapterHeader)
    self.chapter_text = chapter_header_node.text
    self.chapter_number = chapter_header_node.number
    pt.pop(self.nodes)
end

function StoryPageImpl:pop()
    pt.pop(self.nodes)
end

function StoryPageImpl:finish_text()
    local text_node = self.nodes[#self.nodes]
    assert(text_node is Text)
    text_node.text.characters_rendered = #text_node.text.text
end

function StoryPageImpl:add_text_line(dialogue: Dialogue)
    local node = rendered_story_node.text(dialogue)
    pt.add(self.nodes, node)
end

function StoryPageImpl:add_character_customization_menu(
    base_character: Character,
    key: string,
    anim: animation.AnimatedSpriteData
)
    local node = rendered_story_node.character_customization(
        base_character,
        key,
        anim
    )
    pt.add(self.nodes, node)
end

function StoryPageImpl:add_text_input_menu(
    key: string,
    text: Dialogue
)
    local text_node = rendered_story_node.text(
        text
    )
    local input_node = rendered_story_node.text_input(
        key
    )
    pt.add(self.nodes, text_node)
    pt.add(self.nodes, input_node)
end

function StoryPageImpl:clear_page()
    self.nodes = {}
end

return story_page
