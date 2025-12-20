local ui_context = require("src/tactics/ui/ui_context")
require("src/tactics/story/story_page")
require("src/tactics/ui/types")

global type UILayoutId

local record StoryUIContext
    is ui_context.UIContext
    where self.type == "story"

    story_page: StoryPage
end

local story_ui_context = {
    StoryUIContext = StoryUIContext
}

function story_ui_context.new(story_page: StoryPage): StoryUIContext
    local context: StoryUIContext = setmetatable({

    }, { __index = StoryUIContext })
    return context
end

function StoryUIContext:enrich()
    self.layout = "STORY_PAGE"
end

return story_ui_context

