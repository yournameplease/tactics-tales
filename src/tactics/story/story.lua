---@brief
--- The main manager for a story instance. It processes story nodes,
--- handles transitions between story and battle, and manages story state.

local save_system = require("src.tactics.save.save_system")
local battle_manager = require("src.tactics.battle.battle_manager")
local story_menu_manager = require("src.tactics.story.story_menu_manager")
local character_manager = require("src.tactics.character.character_manager")
local stats_service = require("src.tactics.story.statistics.stats_service")
local story_menu_context = require("src.tactics.story.story_menu_context")
local story_ui_context = require("src.tactics.story.story_ui_context")
local story_page = require("src.tactics.story.story_page")
local story_memory = require("src.tactics.story.story_memory")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local dialogue_manager = require("src.tactics.dialogue.dialogue_manager")

---@class BattleServicesBundle Services needed to create a battle.
---@field task_manager TaskManager
---@field animation_manager AnimationManager
---@field event_bus EventBus

---@class ActiveNode
---@field node_id string
---@field node_step integer
---@field definition StoryNode
---@field rendered_node? RenderedStoryNode

---@alias StoryConfig table<string, string> 

---@class Story
---@field package battle_count integer
---@field package story_definition StoryDefinition
---@field package story_config StoryConfig
---@field package game_data GameData
---@field package idle_animation AnimatedSpriteData
---@field package customized_character Character
---@field package text_input string
---@field package save_name? string
---@field package story_id string
---@field package story_page StoryPage
---@field package story_memory StoryMemory
---@field package character_manager CharacterManager
---@field package story_menu_context StoryMenuServices
---@field package menu_manager MenuManager
---@field package stats_service StatsService
---@field package current_node ActiveNode
---@field package battle_manager BattleManager
---@field package dialogue_manager DialogueManager
---@field package active_dialogue ActiveDialogue
---@field package event_listener EventListener
---@field package event_writer EventWriter
---@field package music_player MusicPlayer
---@field package battle_services_bundle BattleServicesBundle
---@field package ui_context UIContextManager
local Story = {}
Story.__index = Story

local story = {
    Story = Story,
}

---@param node_source StoryNode|StoryNodeFactory
---@return StoryNode
function Story:resolve_node_source(node_source)
    if type(node_source) == "function" then
        ---@cast node_source StoryNodeFactory
        return node_source(self.story_config)
    else
        ---@cast node_source StoryNode
        return node_source
    end
end

--- Jump the story to the first step of the named node.
---@param node_id string
function Story:jump_to_node(node_id)
    local node_source = self.story_definition.nodes[node_id][1]
    local node_definition = self:resolve_node_source(node_source)
    
    self.current_node = {
        node_id = node_id,
        node_step = 1,
        definition = node_definition,
    }
    self:handle_new_node()
end

--- Jump the story to a specific step within the named node.
---@param node_id string
---@param node_step integer
function Story:jump_to_node_step(node_id, node_step)
    local node_source = self.story_definition.nodes[node_id][node_step]
    local node_definition = self:resolve_node_source(node_source)
    
    self.current_node = {
        node_id = node_id,
        node_step = node_step,
        definition = node_definition,
    }
    self:handle_new_node()
end

--- The core of the story progression logic. Acts as a state machine that
--- interprets the current story node and triggers the corresponding action,
--- such as showing dialogue, starting a battle, or modifying story memory.
function Story:handle_new_node()
    local node_definition = self.current_node.definition
    log.debug("Handling new node: ", node_definition.type)
    if node_definition.type == 'jump' then
        ---@cast node_definition JumpNode
        self:jump_to_node(node_definition.next_node)
    elseif node_definition.type == 'set_memory' then
        ---@cast node_definition SetMemoryNode
        self.story_memory:set(node_definition.key, story_memory.text(node_definition.value))
        self:advance_node()
    elseif node_definition.type == 'chapter_header' then
        ---@cast node_definition ChapterHeader
        self.story_page:add_chapter_header(node_definition.text, node_definition.chapter_number)
        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {"deleteme"}, -- TODO: this breaks if empty
            {
                auto_advance = false,
            },
            {}
        )
    elseif node_definition.type == 'text' then
        ---@cast node_definition StoryTextNode
        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {node_definition.text},
            {
                can_skip = true,
                auto_advance = false,
            },
            self.story_memory:get_as_map()
        )
        self.story_page:add_text_line(self.active_dialogue)
    elseif node_definition.type == 'battle' then
        ---@cast node_definition BattleNode
        self.story_page:clear_page()
        self.battle_count = self.battle_count + 1
        local battle_id = node_definition.battle_id
        self.battle_manager = battle_manager.new(
            self.battle_count,
            battle_id,
            self.story_config,
            self.game_data,
            self.character_manager,
            self.battle_services_bundle.task_manager,
            self.battle_services_bundle.animation_manager,
            self.battle_services_bundle.event_bus,
            self.music_player,
            self.ui_context
        )
    elseif node_definition.type == 'new_page' then
        self.story_page:clear_page()
        self:advance_node()
    elseif node_definition.type == 'roster_add' then
        ---@cast node_definition RosterAddNode
        local created = self.character_manager:generate_character(
            node_definition.template,
            node_definition.tags or {}
        )
        self.character_manager:persist_player(created)
        self:advance_node()
    elseif node_definition.type == 'character_customizer' then
        ---@cast node_definition CharacterCustomizerNode
        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {"Customize your hero!"},
            {
                can_skip = true,
            },
            self.story_memory:get_as_map()
        )
        self.customized_character = self.character_manager:generate_character("character_customizer_template", {"hero"})
        self.story_menu_context.character_appearance = self.customized_character.appearance
        if node_definition.name_key then
            self.customized_character.name = self.story_memory:get(node_definition.name_key).text
        end
        self.story_page:add_character_customization_menu(
            self.customized_character,
            node_definition.key,
            self.idle_animation
        )
        self.menu_manager:set_menu("MENU_CUSTOMIZE_CHARACTER")
    elseif node_definition.type == 'game_results' then
        self.story_page:add_game_results(
            self.stats_service.story_results
        )
    elseif node_definition.type == 'text_input' then
        ---@cast node_definition TextInputNode
        local key = node_definition.key
        local text = node_definition.text
        local mem = self.story_memory:get_as_map()

        self.menu_manager:set_menu("MENU_TEXT_INPUT")

        local memory_map = setmetatable({}, {
            __index = function(_, k)
                if mem[k] then return mem[k] end

                if k == key then
                    local ctx = self.menu_manager.menu_ctx --[[@as KeyboardMenuContext?]]
                    if ctx then
                        return ctx.keyboard_content
                    end
                end
            end
        })

        self.active_dialogue = self.dialogue_manager:create_dialogue(
            {text},
            {
                can_skip = true,
            },
            memory_map,
            true
            -- false
        )
        self.story_page:add_text_input_menu(key, self.active_dialogue)
    elseif node_definition.type == 'advance' then
        self:advance_node()
    elseif node_definition.type == 'exit_story' then
        self.event_writer:emit("GAME_EXIT_STORY", {})
    elseif node_definition.type == 'save_game' then
        if self.save_name == nil then
            self:advance_node()
        else
            local save_data = {
                character_id_generator = self.character_manager.id_generator,
                story_id = self.story_id,
                story_node_id = self.current_node.node_id,
                story_node_step = self.current_node.node_step + 1,
                story_memory = self.story_memory,
                roster = self.character_manager:get_player_roster(),
                stats = self.stats_service.story_results,
            }
            save_system.save(self.save_name, save_data)

            self.active_dialogue = self.dialogue_manager:create_dialogue(
                {"Progress saved."},
                {
                    can_skip = true,
                    auto_advance = false,
                },
                self.story_memory:get_as_map()
            )
            self.story_page:add_text_line(self.active_dialogue)
        end
    else
        unexpected(node_definition.type)
    end

    self.story_page.story_revision = self.story_page.story_revision + 1
end

--- Advances the story to the next node in the sequence. Performs cleanup
--- from the previous node, increments the node counter, and calls
--- `handle_new_node` to process the newly active node.
function Story:advance_node()
    local node_definition = self.current_node.definition
    -- these probably belong in the story page itself
    if node_definition.type == 'chapter_header' then
        self.story_page:clear_chapter_header()
    end
    if node_definition.type == 'text' then
        self.story_page:finish_text()
    end
    if node_definition.type == 'character_customizer' then
        ---@cast node_definition CharacterCustomizerNode
        self.character_manager:persist_player(self.customized_character)
        self.story_memory:set(
            node_definition.key,
            story_memory.character(self.customized_character.id)
        )
        self.customized_character = nil
        self.menu_manager:clear_menu()
    end
    if node_definition.type == 'text_input' then
        ---@cast node_definition TextInputNode
        self.story_memory:set(
            node_definition.key,
            story_memory.text(self.text_input)
        )
        self.text_input = nil
        self.story_page:pop()
        self.story_page:pop()
        local dialogue = self.dialogue_manager:create_dialogue(
            {node_definition.text},
            {
                can_skip = true,
            },
            self.story_memory:get_as_map(),
            true
            -- false
        )
        -- lol
        dialogue.characters_rendered = 99999
        self.story_page:add_text_line(dialogue)
    end
    self.current_node.node_step = self.current_node.node_step + 1
    self.current_node.definition = self:resolve_node_source(self.story_definition.nodes[self.current_node.node_id][self.current_node.node_step])
    self:handle_new_node()
end

--- Advance to the next story node after text has been read.
function Story:advance_text()
    self:advance_node()
end

--- Handle a battle victory by tearing down the battle and jumping to the victory node.
function Story:handle_battle_victory()
    local node_definition = self.current_node.definition --[[@as BattleNode]]
    assert(node_definition.type == 'battle')
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_victory)
end

--- Handle a battle defeat by tearing down the battle and jumping to the failure node.
function Story:handle_battle_defeat()
    local node_definition = self.current_node.definition --[[@as BattleNode]]
    assert(node_definition.type == 'battle')
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_failure)
end

--- Apply the given appearance selections to the customized character and advance.
---@param appearance table<string, string>
function Story:create_character(appearance)
    ---@diagnostic disable-next-line: missing-fields
    local new_appearance = {} --[[@as CharacterAppearance]]
    self.customized_character.appearance = new_appearance
    for k, a in pairs(appearance) do
        log.debug("Setting character appearance", k, a)
        self.customized_character.appearance[k] = a
    end
    self:advance_node()
end

--- Store submitted text input in memory and advance the node.
---@param text string
function Story:submit_text(text)
    if text == nil or #text == 0 then
        return
    end
    self.text_input = text
    self:advance_node()
end

--- Create and start a new story instance from the beginning.
---@param save_name string? Save file path, or nil for an unsaved story.
---@param story_id string
---@param game_data GameData
---@param story_config StoryConfig
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param event_bus EventBus
---@param music_player MusicPlayer
---@param ui_context UIContextManager
---@return Story
function story.new(
    save_name,
    story_id,
    story_config,
    game_data,
    task_manager,
    animation_manager,
    event_bus,
    music_player,
    ui_context
)
    assert(game_data.stories.data[story_id] ~= nil)

    ---@type Story
    local self = setmetatable({}, Story)
    self.battle_count = 0
    self.story_id = story_id
    self.save_name = save_name

    self.story_definition = game_data.stories.data[self.story_id]
    self.game_data = game_data
    self.story_config = story_config
    log.info("STORY_CONFIG: ", self.story_config)

    self.character_manager = character_manager.new(game_data)

    self.dialogue_manager = dialogue_manager.new()
    self.event_listener = event_listener.new(event_bus)
    self.event_writer = event_writer.new(event_bus)
    self.music_player = music_player

    self.story_menu_context = story_menu_context.new(
        function(appearance) self:create_character(appearance) end,
        function(text) self:submit_text(text) end
    )
    self.story_memory = story_memory.new(self.character_manager)
    self.story_page = story_page.story_page(self.story_memory)
    self.menu_manager = story_menu_manager.new(
        self.story_menu_context,
        event_bus
    )
    self.stats_service = stats_service.new(event_bus)

    self.idle_animation = animation_manager:create_idle_animation()

    self.battle_services_bundle = {
        task_manager = task_manager,
        animation_manager = animation_manager,
        event_bus = event_bus,
    }

    local story_ui_ctx = story_ui_context.new(self.story_page, self.menu_manager)

    self.ui_context = ui_context
    self.ui_context:register_ui_context(story_ui_ctx)

    self.event_listener:on("BATTLE_END", function(payload)
        if payload.result == "VICTORY" then
            self:handle_battle_victory()
        else
            self:handle_battle_defeat()
        end
    end)

    self:jump_to_node(self.story_definition.starting_node)

    return self
end

--- Load a story instance from a saved game file.
---@param save_name string
---@param game_data GameData
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param event_bus EventBus
---@param music_player MusicPlayer
---@param ui_context UIContextManager
---@return Story
function story.load(save_name, game_data, task_manager, animation_manager, event_bus, music_player, ui_context)
    local save_data = save_system.load(save_name)
    assert(save_data, "File failed to load!")

    --TODO: battle count

    local self = story.new(
        save_name,
        save_data.story_id,
        save_data.story_config,
        game_data,
        task_manager,
        animation_manager,
        event_bus,
        music_player,
        ui_context
    )

    self.character_manager.id_generator.id_count = save_data.character_id_count
    self.story_memory:deserialize(save_data.story_memory)
    for _, character_data in ipairs(save_data.roster) do
        local c = self.character_manager:load_character(character_data)
        self.character_manager:persist_player(c)
    end
    self.stats_service.story_results = save_data.stats

    self:jump_to_node_step(save_data.story_node_id, save_data.story_node_step)

    return self
end

--- Process one update tick of the story, handling input for the active node type.
---@param input InputContext
function Story:update(input)
    local current_node = self.current_node.definition
    if current_node.type == 'text'
        or current_node.type == 'chapter_header'
        or current_node.type == 'save_game'
    then
        self.dialogue_manager:update(input)
        if self.active_dialogue ~= nil and self.active_dialogue.finished then
            log.debug("removing dialogue", self.active_dialogue)
            self.active_dialogue = nil
            self:advance_node()
        end
    elseif current_node.type == 'text_input' then
        self.dialogue_manager:update(input)
        if self.active_dialogue ~= nil and self.active_dialogue.finished then
            log.debug("removing dialogue", self.active_dialogue)
            self.active_dialogue = nil
        end
        self.menu_manager:update(input)
    elseif current_node.type == 'character_customizer' then
        self.menu_manager:update(input)
    elseif current_node.type == 'battle' then
        self.battle_manager:update(input)
    elseif current_node.type == 'jump' then
        error('in a jump node during update')
    else
        log.warn("Unexpected node, add a case: " .. current_node.type)
        -- unexpected(current_node.type)
        self.menu_manager:update(input)
    end
end

--- Tear down the story, releasing resources and unregistering contexts.
function Story:teardown()
    self.character_manager:teardown()
    self.ui_context:unregister_ui_context("story")
    self.event_listener:teardown()
end

return story
