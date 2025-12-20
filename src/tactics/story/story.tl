
require("src/tactics/debug")

require("src/tactics/types")
require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")

require("src/tactics/data/battles")

require("src/tactics/battle/battle_manager")
require("src/tactics/menu/menu_manager")
require("src/tactics/story/story_menu_manager")
require("src/tactics/systems/service")
local character_manager = require("src/tactics/character/character_manager")
require("src/tactics/turn_manager")
require("src/tactics/battle/tactics/enemy_ai")
local story_menu_context = require("src/tactics/story/story_context")
local story_ui_context = require("src/tactics/story/story_ui_context")
require("src/tactics/story/story_page")
require("src/tactics/ui/ui_context_manager")
local Joypad = require("src/tactics/joypad").Joypad
local StoryTypes = require("src/tactics/story/types")

local STORY_DATA = require("src/tactics/data/story")


global record Story
    record ActiveNode
        node_id: string
        node_step: integer
        definition: StoryTypes.StoryNode
    end
    
    story_id: StoryTypes.StoryId

    story_page: StoryPage

    character_manager: CharacterManager	
    menu_manager: StoryMenuManager
    current_node: ActiveNode

    battle_manager: BattleManager

    jump_to_node: function(self, node_id: string)
    handle_new_node: function(self)
    advance_node: function(self)

    services: GameServiceBundle
end

function Story:jump_to_node(node_id: string)
    local story_definition = STORY_DATA[self.story_id]
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
        self.story_page:add_text_line(node_definition.text)
        self.menu_manager:set_menu("MENU_STORY_TEXT")
    end
    if node_definition is StoryTypes.BattleNode then
        local battle_id = node_definition.battle_id
        self.battle_manager = BattleManager.new(battle_id, self.character_manager, self.services)
    end
    if node_definition is StoryTypes.NewPageNode then
        self.story_page:clear_page()
        self:advance_node()
    end
end

function Story:advance_node()
    local story_definition = STORY_DATA[self.story_id]
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
    self.story_id = story_id

    local story_definition = STORY_DATA[self.story_id]

    self.services.event_bus = services.event_bus as EventBus

    self.character_manager = character_manager.new(self.services.event_bus)
    -- todo node for this
    local hero = self.character_manager:generate_character("village_hero")
    self.character_manager:persist_player(hero)
    
    self.story_page = StoryPage.new()
    self.menu_manager = StoryMenuManager.new(
        story_menu_context.new(),
        self.services.event_bus
    )

    self:jump_to_node(story_definition.starting_node)

    self.services.event_bus:on("STORY_ADVANCE_TEXT", function()
        self:advance_text()
    end)

    local story_ui_context = story_ui_context.new(self.story_page)
    services.ui_context:register_ui_context(story_ui_context)

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
        self.menu_manager:update(joy)
    elseif current_node is StoryTypes.BattleNode then
        self.battle_manager:update(joy)
    elseif current_node is StoryTypes.JumpNode then
        error('in a jump node during update')
    end
end

return Story
