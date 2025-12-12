
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

local StoryTypes = require("src/story/types")

local STORY_DATA = require("src/data/story")


global record Story
    record NodePosition
        node_id: string
        node_step: integer
    end
    
    story_ctx: StoryContext
    current_node: NodePosition
    current_node_type: StoryTypes.StoryNodeType

    battle_manager: BattleManager

    jump_to_node: function(self, node_id: string)
    handle_new_node: function(self)
    advance_node: function(self)
end

function Story:jump_to_node(node_id: string)
    self.current_node = {
        node_id = node_id,
        node_step = 1
    }

    self:handle_new_node()
end

function Story:handle_new_node()
    local story_definition = STORY_DATA[self.story_ctx.story_id]
    local node = story_definition.nodes[self.current_node.node_id][self.current_node.node_step]
    local new_node_type = node.type
    self.current_node_type = new_node_type
    LOG.debug("Handling new node: ", new_node_type)
    if node is StoryTypes.JumpNode then
        self:jump_to_node(node.next_node)
    end
    if node is StoryTypes.TextNode then
        self.story_ctx.story_page:add_text_line(node.text)
        self.story_ctx.menu_manager:set_menu("MENU_STORY_TEXT")
    end
    if node is StoryTypes.BattleNode then
        local battle_id = node.battle_id
        self.battle_manager = BattleManager.new(battle_id, self.story_ctx)
    end
end

function Story:advance_node()
    self.current_node.node_step = self.current_node.node_step + 1
    self:handle_new_node()
end

function Story:advance_text()
    self:advance_node()
end

function Story.new(story_id: StoryTypes.StoryId, services: GameServiceBundle): Story 
    assert(STORY_DATA[story_id] ~= nil)

    local self: Story = setmetatable({}, { __index = Story })
    self.story_ctx = StoryContext.new(services)
    self.story_ctx.story_id = story_id

    local story_definition = STORY_DATA[self.story_ctx.story_id]

    self.story_ctx.services.event_bus = services.event_bus as EventBus
    
    self.story_ctx.story_page = StoryPage.new()
    self.story_ctx.menu_manager = StoryMenuManager.new(self.story_ctx)

    self:jump_to_node(story_definition.starting_node)

    self.story_ctx.services.event_bus:on("STORY_ADVANCE_TEXT", function()
        self:advance_text()
    end)

    return self
end

function Story:update(joy: Joypad)
    if self.current_node_type == 'text' then
        self.story_ctx.menu_manager:update(joy)
    elseif self.current_node_type == 'battle' then
        self.battle_manager:update(joy)
    elseif self.current_node_type == 'jump' then
        error('in a jump node during update')
    end
end

return Story
