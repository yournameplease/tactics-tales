require("src/tactics/ui/types")
require("src/tactics/battle/tactics/tactics_engine")
require("src/tactics/turn_manager")
require("src/tactics/story/story_context")

global type UILayoutId

global record StoryUIContext
    ctx: StoryContext

    layout: UILayoutId
end

function StoryUIContext.new(ctx: StoryContext): StoryUIContext
    local context: StoryUIContext = setmetatable({
        ctx = ctx
    }, { __index = StoryUIContext })
    return context
end

function StoryUIContext:enrich()
    self.layout = "STORY_PAGE"

end

return StoryUIContext

