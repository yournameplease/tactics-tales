require("src/types")
require("src/util")

global record StoryPageState
    is TransientGameService
    where self.id == 'story_page_state'

    text: {string}
end

function StoryPageState:init(_service_manager: ServiceManager, _services: { ServiceId: GameService })
    self.text = {}
end

function StoryPageState.new(): StoryPageState
    local self: StoryPageState = setmetatable({
        id = 'story_page_state',
        dependencies = {},
    }, { __index = StoryPageState })
    return self
end

-- data access

function StoryPageState:add_text_line(text: string)
    add(self.text, text)
end

function StoryPageState:clear_page()
    self.text = {}
end



return StoryPageState
