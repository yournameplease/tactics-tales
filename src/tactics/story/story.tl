
require("src/tactics/debug")

require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")

require("src/tactics/data/battles")

require("src/tactics/animation")
require("src/tactics/battle/battle_manager")
require("src/tactics/menu/menu_manager")
require("src/tactics/story/story_menu_manager")
require("src/tactics/systems/service")
local character_manager = require("src/tactics/character/character_manager")
require("src/tactics/turn_manager")
require("src/tactics/battle/tactics/enemy_ai")
local story_menu_context = require("src/tactics/story/story_menu_context")
local story_ui_context = require("src/tactics/story/story_ui_context")
local story_page = require("src/tactics/story/story_page")
require("src/tactics/ui/ui_context_manager")
local Joypad = require("src/tactics/joypad").Joypad
local story_types = require("src/tactics/story/types")
local story_node = story_types.story_node
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle

local STORY_DATA = require("src/tactics/data/story")


global record Story
    record ActiveNode
        node_id: string
        node_step: integer
        definition: story_node.StoryNode
        rendered_node: story_page.rendered_story_node.RenderedStoryNode
    end

    idle_animation: AnimatedSpriteData
    customized_character: Character
    
    story_id: story_types.StoryId

    story_page: StoryPage

    character_manager: character_manager.CharacterManager	
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
    if node_definition is story_node.JumpNode then
        self:jump_to_node(node_definition.next_node)
    elseif node_definition is story_node.StoryTextNode then
        self.story_page:add_text_line(node_definition.text)
        self.menu_manager:set_menu("MENU_STORY_TEXT")
    elseif node_definition is story_node.BattleNode then
        local battle_id = node_definition.battle_id
        self.battle_manager = BattleManager.new(battle_id, self.character_manager, self.services)
    elseif node_definition is story_node.NewPageNode then
        self.story_page:clear_page()
        self:advance_node()
    elseif node_definition is story_node.RosterAddNode then
        local character = self.character_manager:generate_character(node_definition.template)
        self.character_manager:persist_player(character)
        self:advance_node()
    elseif node_definition is story_node.CharacterCustomizerNode then
        self.story_page:add_text_line("Customize your hero!")
        self.customized_character = self.character_manager:generate_character("village_hero")
        self.story_page:add_character_customization_menu(self.customized_character, self.idle_animation)
        self.menu_manager:set_menu("MENU_CUSTOMIZE_CHARACTER")
    elseif node_definition is story_node.ExitStoryNode then
        self.services.event_bus:emit("GAME_EXIT_STORY", {})
    else
        error()
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
    assert(node_definition is story_node.BattleNode)

    self.battle_manager:teardown()    
    self:jump_to_node(node_definition.next_node_victory)
end

function Story:handle_battle_defeat()
    local node_definition = self.current_node.definition
    assert(node_definition is story_node.BattleNode)
    
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_victory)
end

function Story:create_character(ctx: MenuContext)
    local appearance = ctx.character_customization.appearance

    self.customized_character.appearance = {}
    for k,a in pairs(appearance) do
        LOG.debug("Setting character appearance", k, a)
        self.customized_character.appearance[k] = a
    end
    self.character_manager:persist_player(self.customized_character)
    self.customized_character = nil
    self:advance_node()
end

function Story.new(story_id: story_types.StoryId, services: GameServiceBundle): Story 
    assert(STORY_DATA[story_id] ~= nil)

    local self: Story = setmetatable({}, { __index = Story })
    self.story_id = story_id

    local story_definition = STORY_DATA[self.story_id]

    self.services = services

    self.character_manager = character_manager.new(self.services.event_bus)
    
    self.story_page = story_page.story_page()
    self.menu_manager = StoryMenuManager.new(
        story_menu_context.new(),
        self.services.event_bus
    )

    self.idle_animation = self.services.animation_manager:create_idle_animation()

    self.services.event_bus:on("STORY_ADVANCE_TEXT", function()
        self:advance_text()
    end)
    self.services.event_bus:on("STORY_CREATE_CHARACTER", function(ctx: MenuContext)
        self:create_character(ctx)
    end)

    local story_ui_ctx = story_ui_context.new(self.story_page, self.menu_manager)
    services.ui_context:register_ui_context(story_ui_ctx)

    services.event_bus:on("BATTLE_END_VICTORY", function()
        self:handle_battle_victory( )
    end)
    services.event_bus:on("BATTLE_END_DEFEAT", function()
        self:handle_battle_defeat( )
    end)
    
    self:jump_to_node(story_definition.starting_node)
    
    return self
end

function Story:update(joy: Joypad)
    local current_node = self.current_node.definition
    if current_node is story_node.StoryTextNode
        or current_node is story_node.CharacterCustomizerNode then
        self.menu_manager:update(joy)
    elseif current_node is story_node.BattleNode then
        self.battle_manager:update(joy)
    elseif current_node is story_node.JumpNode then
        error('in a jump node during update')
    else
        error(current_node.type)
    end
end

function Story:teardown()
    self.character_manager:teardown()    
end

return Story
