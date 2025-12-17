
require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_manager")
require("src/menu/menu_manager")
require("src/story/story_menu_manager")
require("src/systems/service")
local character_manager = require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/story/story_context")
require("src/story/story_page")
require("src/ui/ui_context_manager")

local StoryTypes = require("src/story/types")

local STORY_DATA = require("src/data/story")


global record Story
    record ActiveNode
        node_id: string
        node_step: integer
        definition: StoryTypes.StoryNode
    end
    
    story_ctx: StoryContext
    current_node: ActiveNode

    battle_manager: BattleManager

    jump_to_node: function(self, node_id: string)
    handle_new_node: function(self)
    advance_node: function(self)
end

function Story:jump_to_node(node_id: string)
    local story_definition = STORY_DATA[self.story_ctx.story_id]
    local node_definition = story_definition.nodes[node_id][1]
    self.current_node = {
        node_id = node_id,
        node_step = 1,
        definition = node_definition
    }

    self:handle_new_node()
end

function Story:handle_new_node()
    local node_definition = self.current_node.definition
    LOG.debug("Handling new node: ", node_definition.type)
    if node_definition is StoryTypes.JumpNode then
        self:jump_to_node(node_definition.next_node)
    end
    if node_definition is StoryTypes.TextNode then
        self.story_ctx.story_page:add_text_line(node_definition.text)
        self.story_ctx.menu_manager:set_menu("MENU_STORY_TEXT")
    end
    if node_definition is StoryTypes.BattleNode then
        local battle_id = node_definition.battle_id
        self.battle_manager = BattleManager.new(battle_id, self.story_ctx)
    end
    if node_definition is StoryTypes.NewPageNode then
        self.story_ctx.story_page:clear_page()
        self:advance_node()
    end
end

function Story:advance_node()
    local story_definition = STORY_DATA[self.story_ctx.story_id]
    self.current_node.node_step = self.current_node.node_step + 1
    self.current_node.definition = story_definition.nodes[self.current_node.node_id][self.current_node.node_step]
    self:handle_new_node()
end

function Story:advance_text()
    self:advance_node()
end

function Story:handle_battle_victory()
    local node_definition = self.current_node.definition
    assert(node_definition is StoryTypes.BattleNode)

    self.battle_manager:teardown()    
    self:jump_to_node(node_definition.next_node_victory)
end

function Story:handle_battle_defeat()
    local node_definition = self.current_node.definition
    assert(node_definition is StoryTypes.BattleNode)
    
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_victory)
end

function Story.new(story_id: StoryTypes.StoryId, services: GameServiceBundle): Story 
    assert(STORY_DATA[story_id] ~= nil)

    local self: Story = setmetatable({}, { __index = Story })
    self.story_ctx = StoryContext.new(services)
    self.story_ctx.story_id = story_id

    local story_definition = STORY_DATA[self.story_ctx.story_id]

    self.story_ctx.services.event_bus = services.event_bus as EventBus

    self.story_ctx.character_manager = character_manager.new(self.story_ctx)
    -- todo node for this
    local hero = self.story_ctx.character_manager:generate_character("village_hero")
    self.story_ctx.character_manager:persist_player(hero)
    
    self.story_ctx.story_page = StoryPage.new()
    self.story_ctx.menu_manager = StoryMenuManager.new(self.story_ctx)

    self:jump_to_node(story_definition.starting_node)

    self.story_ctx.services.event_bus:on("STORY_ADVANCE_TEXT", function()
        self:advance_text()
    end)

    services.ui_context:register_context(self.story_ctx)

    services.event_bus:on("BATTLE_END_VICTORY", function()
        self:handle_battle_victory( )
    end)
    services.event_bus:on("BATTLE_END_DEFEAT", function()
        self:handle_battle_defeat( )
    end)

    return self
end

function Story:update(joy: Joypad)
    local current_node = self.current_node.definition
    if current_node is StoryTypes.TextNode then
        self.story_ctx.menu_manager:update(joy)
    elseif current_node is StoryTypes.BattleNode then
        self.battle_manager:update(joy)
    elseif current_node is StoryTypes.JumpNode then
        error('in a jump node during update')
    end
end

return Story
