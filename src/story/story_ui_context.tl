require("src/ui/types")
require("src/battle/tactics/tactics_engine")
require("src/turn_manager")
require("src/story/story_page_state")

global type UILayoutId

global record StoryUIContext
    is TransientGameService
    where self.id == 'story_ui_context'

    story_page_state: StoryPageState

    layout: UILayoutId
end

function StoryUIContext:init(_service_manager: ServiceManager, services: { ServiceId: GameService })
    self.layout = "STORY_PAGE"

    self.story_page_state = services.story_page_state as StoryPageState
end

function StoryUIContext.new(): StoryUIContext
    local context: StoryUIContext = setmetatable({
        id = "story_ui_context",
        dependencies = {
        }
    }, { __index = StoryUIContext })
    return context
end

function StoryUIContext:enrich()
    self.layout = "STORY_PAGE"

end

return StoryUIContext

