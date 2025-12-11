
require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_manager")
require("src/menu/menu_manager")
require("src/menu/story_menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/story/story_ui_context")
require("src/story/story_page")

local Story = require("src/story/types")

local STORY_DATA = require("src/data/story")


global record Story
    record NodePosition
        node_id: string
        node_step: integer
    end
    
    story_id: StoryId

    current_node: NodePosition
    current_node_type: Story.StoryNodeType

    service_manager: ServiceManager

    story_page: StoryPage
    story_ui_context: StoryUIContext
    menu_manager: StoryMenuManager

    battle_manager: BattleManager

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
    local new_node_type = node.type
    self.current_node_type = new_node_type
    LOG.debug("Handling new node: ", new_node_type)
    if node is Story.JumpNode then
        self:jump_to_node(node.next_node)
    end
    if node is Story.TextNode then
        self.story_page:add_text_line(node.text)
        self.menu_manager:set_menu("MENU_STORY_TEXT")
    end
    if node is Story.BattleNode then
        local battle_id = node.battle_id
        self.battle_manager = self.service_manager:register_transient(BattleManager.new(battle_id))
    end
end

function StoryManager:advance_node()
    self.current_node.node_step = self.current_node.node_step + 1
    self:handle_new_node()
end

function StoryManager:advance_text()
    self:advance_node()
end

function StoryManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
    local story_definition = STORY_DATA[self.story_id]

    self.event_bus = services.event_bus as EventBus
    self.service_manager = services.service_manager as ServiceManager
    
    self.story_page = service_manager:register_transient(StoryPage.new())
    self.story_ui_context = service_manager:register_transient(StoryUIContext.new())
    self.menu_manager = service_manager:register_transient(StoryMenuManager.new())

    self:jump_to_node(story_definition.starting_node)

    self.event_bus:on("STORY_ADVANCE_TEXT", function()
        self:advance_text()
    end)
end

function StoryManager.new(story_id: StoryId): StoryManager 
    assert(STORY_DATA[story_id] ~= nil)

    local self: StoryManager = setmetatable({
        id = 'story_manager',
        dependencies = {
            "service_manager",
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
    if self.current_node_type == 'text' then
        self.menu_manager:update(joy)
    elseif self.current_node_type == 'battle' then
        self.battle_manager:update(joy)
    elseif self.current_node_type == 'jump' then

    end
end

return StoryManager
