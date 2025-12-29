require("src/tactics/types")
require("src/tactics/util")

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

function rendered_story_node.character_customization(): RenderedStoryNode
    local node: rendered_story_node.CharacterCustomization = {
        type = 'character_customization',
    }
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
    pt.add(self.nodes, rendered_story_node.text(text))
end

function StoryPage:add_character_customization_menu()
    pt.add(self.nodes, rendered_story_node.character_customization())
    
end

function StoryPage:clear_page()
    self.nodes = {}
end



return story_page
