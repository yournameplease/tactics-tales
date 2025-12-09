require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_manager")
require("src/menu/menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/story/story_ui_context")
require("src/story/story_page_state")
local Story = require("src/story/types")

local STORY_DATA = require("src/data/story")


global record StoryManager
    is TransientGameService
    where self.id == 'story_manager'

    record NodePosition
        node_id: string
        node_step: integer
    end
    
    story_id: StoryId

    current_node: NodePosition

    story_page_state: StoryPageState
    story_ui_context: StoryUIContext

    jump_to_node: function(self, node_id: string)
    handle_new_node: function(self)
    advance_node: function(self)
end

function StoryManager:jump_to_node(node_id: string)
    self.current_node = {
        node_id = node_id,
        node_step = 1
    }

    self:handle_new_node()
end

function StoryManager:handle_new_node()
    local story_definition = STORY_DATA[self.story_id]
    local node = story_definition.nodes[self.current_node.node_id][self.current_node.node_step]

    if node is Story.JumpNode then
        self:jump_to_node(node.next_node)
    end
    if node is Story.TextNode then
        self.story_page_state:add_text_line(node.text)
    end
    if node is Story.BattleNode then

    end
end

function StoryManager:advance_node()
    self.current_node.node_step = self.current_node.node_step + 1
    self:handle_new_node()
end

function StoryManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
    local story_definition = STORY_DATA[self.story_id]

    self.story_page_state = service_manager:register_transient(StoryPageState.new())
    self.story_ui_context = service_manager:register_transient(StoryUIContext.new())

    self:jump_to_node(story_definition.starting_node)
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

function StoryManager:update(joy: Joypad)
    
end

return StoryManager
