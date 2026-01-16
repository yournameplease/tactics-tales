local animation = require("src/tactics/animation")
local drawable_character = require("src/tactics/story/drawable_character")
local story_memory = require("src/tactics/story/story_memory")
local Character = require("src/tactics/character/object/character").Character
local dialogue_manager = require("src/tactics/dialogue/dialogue_manager")
local DialogueManager = dialogue_manager.DialogueManager
local Dialogue = require("src/tactics/dialogue/dialogue").Dialogue
local InputContext = require("src/tactics/input/input_context").InputContext

local enum RenderedStoryNodeType
    "text"
    "character_customization"
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

local record ChapterHeader
    is RenderedStoryNode
    where self.type == "chapter_header"
    text: string
    number: integer
end

local rendered_story_node = {
    RenderedStoryNode = RenderedStoryNode,
    Text = Text,
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

local interface StoryPage
    nodes: {RenderedStoryNode}
    chapter_text: string
    chapter_number: integer
    
    update: function(self, input: InputContext)
    add_chapter_header: function(self, text: string, number: integer)
    clear_chapter_header: function(self)
    finish_text: function(self)
    add_text_line: function(self, text: string)
    add_character_customization_menu: function(self, base_character: Character, key: string, anim: animation.AnimatedSpriteData)
    clear_page: function(self)
end

local story_page = {
    rendered_story_node = rendered_story_node,
    StoryPage = StoryPage,
}

local record StoryPageImpl
    is StoryPage
    dialogue_manager: DialogueManager
    story_memory: story_memory.StoryMemory
end

function story_page.story_page(
    story_mem: story_memory.StoryMemory
): StoryPage
    local self: StoryPageImpl = setmetatable({
        dialogue_manager = dialogue_manager.new(),
        story_memory = story_mem,
    }, { __index = StoryPageImpl })
    self.nodes = {}
    return self
end

function StoryPageImpl:update(input: InputContext)
    self.dialogue_manager:update(input)
end

-- data access

function StoryPageImpl:add_chapter_header(text: string, number: integer)
    local node = rendered_story_node.chapter_header(text, number)
    pt.add(self.nodes, node)
end

-- 
function StoryPageImpl:clear_chapter_header()
    local chapter_header_node = self.nodes[#self.nodes]
    assert(chapter_header_node is ChapterHeader)
    self.chapter_text = chapter_header_node.text
    self.chapter_number = chapter_header_node.number
    pt.pop(self.nodes)
end

function StoryPageImpl:finish_text()
    local text_node = self.nodes[#self.nodes]
    assert(text_node is Text)
    text_node.text.characters_rendered = #text_node.text.text
end

function StoryPageImpl:add_text_line(text: string)
    local dialogue = self.dialogue_manager:create_dialogue(
        text,
        {
            can_skip = true,
        },
        self.story_memory:get_as_map()
    )
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

function StoryPageImpl:clear_page()
    self.nodes = {}
end

return story_page
