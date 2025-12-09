require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_state")
require("src/battle/tactics/battle_unit")
require("src/battle/tile_manager")
require("src/battle/tactics/tactics_engine")
require("src/battle/map/map_manager")
require("src/menu/menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")

local STORY_DATA = require("src/data/story")

global record StoryManager
    is TransientGameService
    where self.id == 'story_manager'

    story_id: StoryId

end


function StoryManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
    local story_definition = STORY_DATA[self.story_id]

end

function StoryManager.new(story_id: StoryId): StoryManager 
    assert(STORY_DATA[story_id] ~= nil)

    local self: StoryManager = setmetatable({
        id = 'story_manager',
        dependencies = {
            "event_bus",
            "animation_manager",
            "task_manager",
            "character_manager",
        }
    }, { __index = StoryManager })
    self.story_id = story_id

    return self
end

function StoryManager:update()
end

return StoryManager
