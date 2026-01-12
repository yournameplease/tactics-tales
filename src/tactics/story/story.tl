
require("src/tactics/debug")

local animation = require("src/tactics/animation")
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local battle_manager = require("src/tactics/battle/battle_manager")
local story_menu_manager = require("src/tactics/story/story_menu_manager")
local character_manager = require("src/tactics/character/character_manager")
local story_menu_context = require("src/tactics/story/story_menu_context")
local story_ui_context = require("src/tactics/story/story_ui_context")
local story_page = require("src/tactics/story/story_page")
local InputContext = require("src/tactics/input/input_context").InputContext
local story_types = require("src/tactics/story/types")
local story_node = story_types.story_node
local StoryId = story_types.StoryId
local StoryDefinition = story_types.StoryDefinition
local GameData = require("src/tactics/game_data").GameData
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle
local Character = require("src/tactics/character/object/character").Character

local record Story
    record ActiveNode
        node_id: string
        node_step: integer
        definition: story_node.StoryNode
        rendered_node: story_page.rendered_story_node.RenderedStoryNode
    end

    story_definition: StoryDefinition
    game_data: GameData

    idle_animation: animation.AnimatedSpriteData
    customized_character: Character
    
    story_id: story_types.StoryId

    story_page: story_page.StoryPage

    character_manager: character_manager.CharacterManager	
    menu_manager: story_menu_manager.StoryMenuManager
    current_node: ActiveNode

    battle_manager: battle_manager.BattleManager

    jump_to_node: function(self, node_id: string)
    handle_new_node: function(self)
    advance_node: function(self)

    services: GameServiceBundle
end

local story = {
    Story = Story
}

function Story:jump_to_node(node_id: string)
    local node_definition = self.story_definition.nodes[node_id][1]
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
    elseif node_definition is story_node.ChapterHeader then
        self.story_page:add_chapter_header(node_definition.text, node_definition.chapter_number)
        self.menu_manager:set_menu("MENU_STORY_TEXT")
    elseif node_definition is story_node.StoryTextNode then
        self.story_page:add_text_line(node_definition.text)
        self.menu_manager:set_menu("MENU_STORY_TEXT")
    elseif node_definition is story_node.BattleNode then
        local battle_id = node_definition.battle_id
        self.battle_manager = battle_manager.new(battle_id, self.game_data, self.character_manager, self.services)
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
        unexpected(node_definition.type)
    end
end

function Story:advance_node()
    local node_definition = self.current_node.definition
    if node_definition is story_node.ChapterHeader then
        self.story_page:clear_chapter_header()
    end
    self.current_node.node_step = self.current_node.node_step + 1
    self.current_node.definition = self.story_definition.nodes[self.current_node.node_id][self.current_node.node_step]
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

function story.new(
    story_id: StoryId,
    game_data: GameData,
    services: GameServiceBundle
): Story
    assert(game_data.stories.data[story_id] ~= nil)

    local self: Story = setmetatable({}, { __index = Story })
    self.story_id = story_id

    self.story_definition = game_data.stories.data[self.story_id]
    self.game_data = game_data

    self.services = services

    self.character_manager = character_manager.new(
        game_data,
        self.services.event_bus
    )
    
    self.story_page = story_page.story_page()
    self.menu_manager = story_menu_manager.new(
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
    
    self:jump_to_node(self.story_definition.starting_node)
    
    return self
end

function Story:update(input: InputContext)
    local current_node = self.current_node.definition
    if current_node is story_node.StoryTextNode
        or current_node is story_node.CharacterCustomizerNode
        or current_node is story_node.ChapterHeader
    then
        self.menu_manager:update(input)
    elseif current_node is story_node.BattleNode then
        self.battle_manager:update(input)
    elseif current_node is story_node.JumpNode then
        error('in a jump node during update')
    else
        LOG.warn("Unexpected node, add a case: "..current_node.type)
        -- unexpected(current_node.type)
        self.menu_manager:update(input)
    end
end

function Story:teardown()
    self.character_manager:teardown()    
end

return story
