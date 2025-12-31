require("src/tactics/types")
require("src/tactics/animation")
local drawable_character = require("src/tactics/story/drawable_character")

local enum RenderedStoryNodeType
    "text"
    "character_customization"
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

local rendered_story_node = {
    RenderedStoryNode = RenderedStoryNode,
    Text = Text,
    CharacterCustomization = CharacterCustomization,
}

function rendered_story_node.text(text: string): RenderedStoryNode
    local node: rendered_story_node.Text = {
        type = 'text',
        text = text,
    }
    return node
end

function rendered_story_node.character_customization(base_character: Character, animation: AnimatedSpriteData): RenderedStoryNode
    local node: rendered_story_node.CharacterCustomization = {
        type = 'character_customization',
    }

    node.character = drawable_character.create_drawable_unit(base_character, "player")
    node.character.animation_data = animation
    return node
end

global record StoryPage
    nodes: {RenderedStoryNode}
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

function StoryPage:add_text_line(text: string)
    local node = rendered_story_node.text(text)
    pt.add(self.nodes, node)
end

function StoryPage:add_character_customization_menu(base_character: Character, animation: AnimatedSpriteData)
    local node = rendered_story_node.character_customization(base_character, animation)
    pt.add(self.nodes, node)
end

function StoryPage:clear_page()
    self.nodes = {}
end



return story_page
