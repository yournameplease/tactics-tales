local animation = require("src.tactics.animation")
local battle_manager = require("src.tactics.battle.battle_manager")
local story_menu_manager = require("src.tactics.story.story_menu_manager")
local character_manager = require("src.tactics.character.character_manager")
local character = require("src.tactics.character.object.character")
local story_menu_context = require("src.tactics.story.story_menu_context")
local story_ui_context = require("src.tactics.story.story_ui_context")
local story_page = require("src.tactics.story.story_page")
local story_memory = require("src.tactics.story.story_memory")
local InputContext = require("src.tactics.input.input_context").InputContext
local story_types = require("src.tactics.story.types")
local story_node = story_types.story_node
local StoryId = story_types.StoryId
local StoryDefinition = story_types.StoryDefinition
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local Character = require("src.tactics.character.object.character").Character
local EventBus = require("src.tactics.systems.event_bus").EventBus
local GameData = require("src.tactics.game_data").GameData
local TaskManager = require("src.tactics.systems.tasks").TaskManager
local AnimationManager = require("src.tactics.animation").AnimationManager
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local dialogue_manager = require("src.tactics.dialogue.dialogue_manager")
local DialogueManager = dialogue_manager.DialogueManager
local Dialogue = require("src.tactics.dialogue.dialogue").Dialogue

---@desc
--- services needed to create a battle
local record BattleServicesBundle
    task_manager: TaskManager
    animation_manager: AnimationManager
    event_bus: EventBus
end

local record ActiveNode
    node_id: string
    node_step: integer
    definition: story_node.StoryNode
    rendered_node: story_page.rendered_story_node.RenderedStoryNode
end

local interface Story
    update: function(self, input: InputContext)
    teardown: function(self)
end

local story = {
    Story = Story
}

local record StoryImpl
    is Story

    story_definition: StoryDefinition
    game_data: GameData

    idle_animation: animation.AnimatedSpriteData
    customized_character: Character
    
    story_id: story_types.StoryId

    story_page: story_page.StoryPage
    story_memory: story_memory.StoryMemory

    character_manager: character_manager.CharacterManager	
    menu_manager: story_menu_manager.StoryMenuManager
    current_node: ActiveNode

    battle_manager: battle_manager.BattleManager

    jump_to_node: function(self, node_id: string)
    handle_new_node: function(self)
    advance_node: function(self)

    dialogue_manager: DialogueManager
    active_dialogue: Dialogue
    event_listener: event_listener.EventListener
    event_writer: event_writer.EventWriter

    battle_services_bundle: BattleServicesBundle
    ui_context: UIContextManager

end

function StoryImpl:jump_to_node(node_id: string)
    local node_definition = self.story_definition.nodes[node_id][1]
    self.current_node = {
        node_id = node_id,
        node_step = 1,
        definition = node_definition
    }

    self:handle_new_node()
end

function StoryImpl:handle_new_node()
    local node_definition = self.current_node.definition
    log.debug("Handling new node: ", node_definition.type)
    if node_definition is story_node.JumpNode then
        self:jump_to_node(node_definition.next_node)
    elseif node_definition is story_node.SetMemoryNode then
        self.story_memory:set(node_definition.key, story_memory.text(node_definition.value))
        self:advance_node()
    elseif node_definition is story_node.ChapterHeader then
        self.story_page:add_chapter_header(node_definition.text, node_definition.chapter_number)
        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {"test"}, -- todo: make this empty lol
            {
                auto_advance = false,
            },
            {}
        )
    elseif node_definition is story_node.StoryTextNode then
        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {node_definition.text},
            {
                can_skip = true,
                auto_advance = false,
            },
            self.story_memory:get_as_map()
        )
        self.story_page:add_text_line(self.active_dialogue)
    elseif node_definition is story_node.BattleNode then
        local battle_id = node_definition.battle_id
        self.battle_manager = battle_manager.new(
            battle_id,
            self.game_data,
            self.character_manager,
            self.battle_services_bundle.task_manager,
            self.battle_services_bundle.animation_manager,
            self.battle_services_bundle.event_bus,
            self.ui_context
        )
    elseif node_definition is story_node.NewPageNode then
        self.story_page:clear_page()
        self:advance_node()
    elseif node_definition is story_node.RosterAddNode then
        local created = self.character_manager:generate_character(
            node_definition.template,
            node_definition.tags or {}
        )
        self.character_manager:persist_player(created)
        self:advance_node()
    elseif node_definition is story_node.CharacterCustomizerNode then
        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {"Customize your hero!"},
            {
                can_skip = false,
            },
            self.story_memory:get_as_map()
        )
        self.customized_character = self.character_manager:generate_character("village_hero", {"hero"})
        if node_definition.name_key then
            self.customized_character.name = self.story_memory:get(node_definition.name_key).text
        end
        self.story_page:add_character_customization_menu(
            self.customized_character,
            node_definition.key,
            self.idle_animation
        )
        self.menu_manager:set_menu("MENU_CUSTOMIZE_CHARACTER")
    elseif node_definition is story_node.ExitStoryNode then
        self.event_writer:emit("GAME_EXIT_STORY", {})
    else
        unexpected(node_definition.type)
    end
end

function StoryImpl:advance_node()
    local node_definition = self.current_node.definition
    -- these probably belong in the story page itself
    if node_definition is story_node.ChapterHeader then
        self.story_page:clear_chapter_header()
    end
    if node_definition is story_node.StoryTextNode then
        self.story_page:finish_text()
    end
    if node_definition is story_node.CharacterCustomizerNode then
        self.character_manager:persist_player(self.customized_character)
        self.story_memory:set(
            node_definition.key,
            story_memory.character(self.customized_character.id)
        )
        self.customized_character = nil
        self.menu_manager:clear_menu()
    end
    self.current_node.node_step = self.current_node.node_step + 1
    self.current_node.definition = self.story_definition.nodes[self.current_node.node_id][self.current_node.node_step]
    self:handle_new_node()
end

function StoryImpl:advance_text()
    self:advance_node()
end

function StoryImpl:handle_battle_victory()
    local node_definition = self.current_node.definition
    assert(node_definition is story_node.BattleNode)

    self.battle_manager:teardown()    
    self:jump_to_node(node_definition.next_node_victory)
end

function StoryImpl:handle_battle_defeat()
    local node_definition = self.current_node.definition
    assert(node_definition is story_node.BattleNode)
    
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_failure)
end

function StoryImpl:create_character(appearance: {character.CharacterAppearanceKey: string})
    self.customized_character.appearance = {}
    for k,a in pairs(appearance) do
        log.debug("Setting character appearance", k, a)
        self.customized_character.appearance[k] = a
    end
    self:advance_node()
end

function story.new(
    story_id: StoryId,
    game_data: GameData,
    task_manager: TaskManager,
    animation_manager: AnimationManager,
    event_bus: EventBus,
    ui_context: UIContextManager
): Story
    assert(game_data.stories.data[story_id] ~= nil)

    local self: StoryImpl = setmetatable({}, { __index = StoryImpl })
    self.story_id = story_id

    self.story_definition = game_data.stories.data[self.story_id]
    self.game_data = game_data

    self.character_manager = character_manager.new(
        game_data
    )

    self.dialogue_manager = dialogue_manager.new()
    self.event_listener = event_listener.new(event_bus)
    self.event_writer = event_writer.new(event_bus)
    
    self.story_memory = story_memory.new(self.character_manager)
    self.story_page = story_page.story_page(self.story_memory)
    self.menu_manager = story_menu_manager.new(
        story_menu_context.new(
            function(appearance: {character.CharacterAppearanceKey: string}) self:create_character(appearance) end
        ),
        event_bus
    )

    self.idle_animation = animation_manager:create_idle_animation()

    self.battle_services_bundle = {
        task_manager = task_manager,
        animation_manager = animation_manager,
        event_bus = event_bus,
    }

    local story_ui_ctx = story_ui_context.new(self.story_page, self.menu_manager)

    self.ui_context = ui_context
    self.ui_context:register_ui_context(story_ui_ctx)

    self.event_listener:on("BATTLE_END_VICTORY", function()
        self:handle_battle_victory( )
    end)
    self.event_listener:on("BATTLE_END_DEFEAT", function()
        self:handle_battle_defeat( )
    end)
    
    self:jump_to_node(self.story_definition.starting_node)
    
    return self
end

function StoryImpl:update(input: InputContext)
    local current_node = self.current_node.definition
    if current_node is story_node.StoryTextNode
        or current_node is story_node.ChapterHeader
    then
        self.dialogue_manager:update(input)
        if self.active_dialogue ~= nil and self.active_dialogue.finished then
            log.debug("removing dialogue", self.active_dialogue)
            self.active_dialogue = nil
            self:advance_node()
        end
    elseif current_node is story_node.CharacterCustomizerNode then
        self.menu_manager:update(input)
    elseif current_node is story_node.BattleNode then
        self.battle_manager:update(input)
    elseif current_node is story_node.JumpNode then
        error('in a jump node during update')
    else
        log.warn("Unexpected node, add a case: "..current_node.type)
        -- unexpected(current_node.type)
        self.menu_manager:update(input)
    end
end

function StoryImpl:teardown()
    self.character_manager:teardown()    
    self.ui_context:unregister_ui_context("story")
    self.event_listener:teardown()
end

return story
