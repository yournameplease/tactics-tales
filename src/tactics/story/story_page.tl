local animation = require("src/tactics/animation")
local drawable_character = require("src/tactics/story/drawable_character")
local Character = require("src/tactics/character/object/character").Character

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
    text: string
end

local record CharacterCustomization
    is RenderedStoryNode
    where self.type == "character_customization"
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

function rendered_story_node.text(text: string): RenderedStoryNode
    local node: Text = {
        type = 'text',
        text = text,
    }
    return node
end

function rendered_story_node.character_customization(base_character: Character, anim: animation.AnimatedSpriteData): RenderedStoryNode
    local node: rendered_story_node.CharacterCustomization = {
        type = 'character_customization',
    }

    node.character = drawable_character.create_drawable_unit(
        base_character,
        "player",
        { vertical = "down", horizontal = "left" }
    )
    node.character.animation_data = anim
    return node
end

local record StoryPage
    nodes: {RenderedStoryNode}
    chapter_text: string
    chapter_number: integer
end

local story_page = {
    rendered_story_node = rendered_story_node,
    StoryPage = StoryPage,
}

function story_page.story_page(): StoryPage
    local self: StoryPage = setmetatable({}, { __index = StoryPage })
    self.nodes = {}
    return self
end

-- data access

function StoryPage:add_chapter_header(text: string, number: integer)
    local node = rendered_story_node.chapter_header(text, number)
    pt.add(self.nodes, node)
end

-- 
function StoryPage:clear_chapter_header()
    local chapter_header_node = self.nodes[#self.nodes]
    assert(chapter_header_node is ChapterHeader)
    self.chapter_text = chapter_header_node.text
    self.chapter_number = chapter_header_node.number
    pt.pop(self.nodes)
end

function StoryPage:add_text_line(text: string)
    local node = rendered_story_node.text(text)
    pt.add(self.nodes, node)
end

function StoryPage:add_character_customization_menu(base_character: Character, anim: animation.AnimatedSpriteData)
    local node = rendered_story_node.character_customization(base_character, anim)
    pt.add(self.nodes, node)
end

function StoryPage:clear_page()
    self.nodes = {}
end

return story_page
