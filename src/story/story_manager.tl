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
require("src/story/story_context")
require("src/story/story_page")
require("src/story/story_context")

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
    current_node_type: Story.StoryNodeType

    service_manager: ServiceManager

    story_ctx: StoryContext

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
        self.story_ctx.story_page:add_text_line(node.text)
        self.story_ctx.menu_manager:set_menu("MENU_STORY_TEXT")
    end
    if node is Story.BattleNode then
        local battle_id = node.battle_id
        self.story_ctx.battle_manager = BattleManager.new(battle_id, self.story_ctx)
    end
end

function StoryManager:advance_node()
    self.current_node.node_step = self.current_node.node_step + 1
    self:handle_new_node()
end

function StoryManager:advance_text()
    self:advance_node()
end

function StoryManager.new(story_id: StoryId, services: GameServiceBundle): StoryManager 
    assert(STORY_DATA[story_id] ~= nil)

    local self: StoryManager = setmetatable({}, { __index = StoryManager })
    self.story_id = story_id
    self.story_ctx = StoryContext.new(services)

    self.story_ctx.character_manager = CharacterManager.new(self.story_ctx)

    local story_definition = STORY_DATA[self.story_id]

    self.story_ctx.story_page = StoryPage.new()
    self.story_ctx.menu_manager = StoryMenuManager.new()

    self:jump_to_node(story_definition.starting_node)

    self.story_ctx.services.event_bus:on("STORY_ADVANCE_TEXT", function()
        self:advance_text()
    end)

    
    
    return self
end

function StoryManager:update(joy: Joypad)
    if self.current_node_type == 'text' then
        self.story_ctx.menu_manager:update(joy)
    elseif self.current_node_type == 'battle' then
        self.story_ctx.battle_manager:update(joy)
    elseif self.current_node_type == 'jump' then

    end
end

return StoryManager
