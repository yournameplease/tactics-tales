---@brief
--- The main manager for a campaign instance. It processes campaign nodes,
--- handles transitions between campaign and battle, and manages campaign state.

local save_system = require("src.tactics.save.save_system")
local random = require("src.tactics.util.random")
local HANDLERS = require("src.tactics.campaign.handlers.node_handlers")
local campaign_menu_manager = require("src.tactics.campaign.campaign_menu_manager")
local character_manager = require("src.tactics.character.character_manager")
local stats_service = require("src.tactics.campaign.statistics.stats_service")
local campaign_ui_context = require("src.tactics.campaign.campaign_ui_context")
local campaign_page = require("src.tactics.campaign.campaign_page")
local page_flip_animator = require("src.tactics.animation.page_flip_animator")
local campaign_state = require("src.tactics.campaign.campaign_state")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local dialogue_manager = require("src.tactics.dialogue.dialogue_manager")

---@class CampaignMenuServices : GameContext
---@field character_appearance? table<string, string> Map from CharacterAppearanceKey to current value; set before opening the character creation menu.
---@field handle_create_character fun(appearance: table<string, string>) Callback invoked when the player confirms character creation.
---@field handle_submit_text fun(text: string) Callback invoked when the player submits text input.
---@field selection_options? SelectOptionEntry[] Options for the active select_option node; set before opening the selection menu.
---@field handle_select_option fun(option_id: string) Callback invoked when the player confirms an option selection.

---@class BattleServicesBundle Services needed to create a battle.
---@field task_manager TaskManager
---@field animation_manager AnimationManager
---@field event_bus EventBus

---@class ActiveNode
---@field node_id string
---@field node_step integer
---@field definition CampaignNode
---@field rendered_node? RenderedCampaignNode

---@alias CampaignConfig table<string, string>

---@class Campaign
---@field package battle_count integer
---@field package campaign_definition CampaignDefinition
---@field package campaign_config CampaignConfig
---@field package battle_config BattleConfig
---@field package game_data GameData
---@field package idle_animation AnimatedSpriteData
---@field package customized_character Character
---@field package text_input string
---@field package selected_option string?
---@field package save_name? string
---@field package campaign_id string
---@field package campaign_page CampaignPage
---@field package page_flip_animator PageFlipAnimator
---@field package campaign_state CampaignState
---@field package character_manager CharacterManager
---@field package campaign_menu_context CampaignMenuServices
---@field package menu_manager MenuManager
---@field package stats_service StatsService
---@field package current_node ActiveNode
---@field package campaign_seed integer Seed used to derive battle-level RNG seeds.
---@field package campaign_rng RngInstance Campaign-level RNG instance.
---@field package rng_context CampaignRngContext RNG context passed to all factory functions.
---@field package battle_manager BattleManager
---@field package dialogue_manager DialogueManager
---@field package active_dialogue ActiveDialogue
---@field package event_listener EventListener
---@field package event_writer EventWriter
---@field package music_player MusicPlayer
---@field package battle_services_bundle BattleServicesBundle
---@field package ui_context UIContextManager
---@field package input_service InputService
---@field return_stack {node_id: string, node_step: integer}[]
local Campaign = {}
Campaign.__index = Campaign

local campaign = {
    Campaign = Campaign,
}

---@param node_source CampaignNode|CampaignNodeFactory
---@return CampaignNode
function Campaign:resolve_node_source(node_source)
    if type(node_source) == "function" then
        ---@cast node_source CampaignNodeFactory
        return node_source(self.campaign_config, self.rng_context, self.campaign_state:get_as_map())
    else
        ---@cast node_source CampaignNode
        return node_source
    end
end

--- Normalize a CampaignNodeSource to a CampaignNode[] for sequential access.
---@param source CampaignNodeSource
---@return CampaignNode[]
function Campaign:resolve_to_array(source)
    if type(source) == "function" then
        return self:resolve_to_array(source(self.campaign_config, self.rng_context, self.campaign_state:get_as_map()))
    elseif source[1] ~= nil then
        ---@cast source CampaignNode[]
        return source
    else
        ---@cast source CampaignNode
        return { source }
    end
end

--- Jump the campaign to the first step of the named node.
---@param node_id string
function Campaign:jump_to_node(node_id)
    local steps = self:resolve_to_array(self.campaign_definition.nodes[node_id])
    local node_definition = self:resolve_node_source(steps[1])

    self.current_node = {
        node_id = node_id,
        node_step = 1,
        definition = node_definition,
    }
    self:handle_new_node()
end

--- Jump the campaign to a specific step within the named node.
---@param node_id string
---@param node_step integer
function Campaign:jump_to_node_step(node_id, node_step)
    local steps = self:resolve_to_array(self.campaign_definition.nodes[node_id])
    local node_definition = self:resolve_node_source(steps[node_step])

    self.current_node = {
        node_id = node_id,
        node_step = node_step,
        definition = node_definition,
    }
    self:handle_new_node()
end

--- The core of the campaign progression logic. Acts as a state machine that
--- interprets the current campaign node and triggers the corresponding action,
--- such as showing dialogue, starting a battle, or modifying campaign memory.
function Campaign:handle_new_node()
    local node = self.current_node.definition

    local steps = self:resolve_to_array(self.campaign_definition.nodes[self.current_node.node_id])
    if steps[self.current_node.node_step] == nil and #self.return_stack > 0 then
        log.debug("popping return stack")
        local ret = table.remove(self.return_stack)
        self:jump_to_node_step(ret.node_id, ret.node_step)
        return
    end

    log.debug("Handling new node: ", node.type)
    local h = assert(HANDLERS[node.type], "Unknown node type: " .. tostring(node.type))
    h.enter(self, node)
    self.campaign_page.campaign_revision = self.campaign_page.campaign_revision + 1
end

--- Advances the campaign to the next node in the sequence. Performs cleanup
--- from the previous node, increments the node counter, and calls
--- `handle_new_node` to process the newly active node.
function Campaign:advance_node()
    local node = self.current_node.definition
    local h = HANDLERS[node.type]
    if h and h.exit then h.exit(self, node) end
    self.current_node.node_step = self.current_node.node_step + 1
    local steps = self:resolve_to_array(self.campaign_definition.nodes[self.current_node.node_id])

    if steps[self.current_node.node_step] == nil and #self.return_stack > 0 then
        log.debug("popping return stack")
        local ret = table.remove(self.return_stack)
        self:jump_to_node_step(ret.node_id, ret.node_step)
        return
    end

    self.current_node.definition = self:resolve_node_source(steps[self.current_node.node_step])
    self:handle_new_node()
end

--- Advance to the next campaign node after text has been read.
function Campaign:advance_text()
    self:advance_node()
end

--- Handle a battle victory by tearing down the battle and jumping to the victory node.
function Campaign:handle_battle_victory()
    local node_definition = self.current_node.definition --[[@as BattleNode]]
    assert(node_definition.type == 'battle')
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_victory)
end

--- Handle a battle defeat by tearing down the battle and jumping to the failure node.
function Campaign:handle_battle_defeat()
    local node_definition = self.current_node.definition --[[@as BattleNode]]
    assert(node_definition.type == 'battle')
    self.battle_manager:teardown()
    self:jump_to_node(node_definition.next_node_failure)
end

--- Apply the given appearance selections to the customized character and advance.
---@param appearance table<string, string>
function Campaign:create_character(appearance)
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
function Campaign:submit_text(text)
    if text == nil or #text == 0 then
        return
    end
    self.text_input = text
    self:advance_node()
end

--- Store the chosen option ID and advance the node.
---@param option_id string
function Campaign:select_option(option_id)
    self.selected_option = option_id
    self:advance_node()
end

--- Create and start a new campaign instance from the beginning.
---@param save_name string? Save file path, or nil for an unsaved campaign.
---@param campaign_id string
---@param game_data GameData
---@param campaign_config CampaignConfig
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param event_bus EventBus
---@param music_player MusicPlayer
---@param ui_context UIContextManager
---@param input_service InputService
---@return Campaign
function campaign.new(
    save_name,
    campaign_id,
    campaign_config,
    game_data,
    task_manager,
    animation_manager,
    event_bus,
    music_player,
    ui_context,
    input_service
)
    assert(game_data.campaigns.data[campaign_id] ~= nil)

    ---@type Campaign
    local self = setmetatable({}, Campaign)
    self.battle_count = 0
    self.campaign_id = campaign_id
    self.save_name = save_name
    self.return_stack = {}

    self.campaign_definition = game_data.campaigns.data[self.campaign_id]
    self.game_data = game_data
    self.campaign_config = campaign_config

    self.campaign_seed = math.max(1, math.floor(rnd(0x7FFFFFFF)))
    self.campaign_rng = random.new(self.campaign_seed)
    self.rng_context = { campaign_rng = self.campaign_rng }

    if type(self.campaign_definition.battle_config) == "function" then
        self.battle_config = self.campaign_definition.battle_config(campaign_config, self.rng_context)
    else
        ---@diagnostic disable-next-line
        self.battle_config = self.campaign_definition.battle_config
    end

    self.character_manager = character_manager.new(game_data)

    self.dialogue_manager = dialogue_manager.new()
    self.event_listener = event_listener.new(event_bus)
    self.event_writer = event_writer.new(event_bus)
    self.music_player = music_player

    ---@type CampaignMenuServices
    self.campaign_menu_context = {
        handle_create_character = function(appearance) self:create_character(appearance) end,
        handle_submit_text = function(text) self:submit_text(text) end,
        handle_select_option = function(option_id) self:select_option(option_id) end,
    }
    self.campaign_state = campaign_state.new(self.character_manager)
    -- Expose live memory to all factory functions (node and battle factories).
    -- Campaign-level factories use campaign_config.memory:get()/set(); the plain
    -- campaign_config fields (e.g. permadeath) are still accessible via __index.
    self.campaign_config = setmetatable({ memory = self.campaign_state }, { __index = campaign_config })
    self.campaign_page = campaign_page.new(self.campaign_state)
    self.page_flip_animator = page_flip_animator.new()
    self.menu_manager = campaign_menu_manager.new(
        self.campaign_menu_context,
        event_bus
    )
    self.stats_service = stats_service.new(event_bus)

    self.idle_animation = animation_manager:create_idle_animation()

    self.battle_services_bundle = {
        task_manager = task_manager,
        animation_manager = animation_manager,
        event_bus = event_bus,
    }

    local campaign_ui_ctx = campaign_ui_context.new(self.campaign_page, self.menu_manager)

    self.ui_context = ui_context
    self.ui_context:register_ui_context(campaign_ui_ctx)
    self.input_service = input_service

    self.event_listener:on("BATTLE_END", function(payload)
        if payload.result == "VICTORY" then
            self:handle_battle_victory()
        else
            self:handle_battle_defeat()
        end
    end)

    self:jump_to_node(self.campaign_definition.starting_node)

    return self
end

--- Load a campaign instance from a saved game file.
---@param save_name string
---@param game_data GameData
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param event_bus EventBus
---@param music_player MusicPlayer
---@param ui_context UIContextManager
---@return Campaign
function campaign.load(save_name, game_data, task_manager, animation_manager, event_bus, music_player, ui_context,
                       input_service)
    local save_data = save_system.load(save_name)
    assert(save_data, "File failed to load!")

    --TODO: battle count

    local self = campaign.new(
        save_name,
        save_data.campaign_id,
        save_data.campaign_config,
        game_data,
        task_manager,
        animation_manager,
        event_bus,
        music_player,
        ui_context,
        input_service
    )

    -- Restore RNG state so future sequences are identical to the saved point.
    if save_data.campaign_seed then self.campaign_seed = save_data.campaign_seed end
    if save_data.campaign_rng_state then self.campaign_rng:set_state(save_data.campaign_rng_state) end

    self.character_manager.id_generator.id_count = save_data.character_id_count
    self.campaign_state:deserialize(save_data.campaign_state)
    for _, character_data in ipairs(save_data.roster) do
        local c = self.character_manager:load_character(character_data)
        self.character_manager:persist_player(c)
    end
    self.stats_service.campaign_results = save_data.stats

    self:jump_to_node_step(save_data.campaign_node_id, save_data.campaign_node_step)

    return self
end

--- Return the campaign's PageFlipAnimator.
---@return PageFlipAnimator
function Campaign:get_page_flip_animator()
    return self.page_flip_animator
end

--- Process one update tick of the campaign, handling input for the active node type.
---@param input InputContext
function Campaign:update(input)
    if not self.page_flip_animator:is_blocking_input() then
        local h = HANDLERS[self.current_node.definition.type]
        if h and h.update then
            h.update(self, input)
        end
    end
end

--- Tear down the campaign, releasing resources and unregistering contexts.
function Campaign:teardown()
    self.character_manager:teardown()
    self.ui_context:unregister_ui_context("campaign")
    self.event_listener:teardown()
end

return campaign
