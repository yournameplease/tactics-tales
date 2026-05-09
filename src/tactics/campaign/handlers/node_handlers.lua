-- Handlers access Campaign @field package fields; Campaign fields are package-scoped to
-- src/tactics/campaign/ but handlers live in the subdirectory handlers/.
---@diagnostic disable: invisible
local save_system = require("src.tactics.save.save_system")
local random = require("src.tactics.util.random")
local battle_manager_module = require("src.tactics.battle.battle_manager")
local campaign_state = require("src.tactics.campaign.campaign_state")
local character = require("src.tactics.character.object.character")

---@param campaign Campaign
---@param input InputContext
local function dialogue_update(campaign, input)
    campaign.dialogue_manager:update(input)
    if campaign.active_dialogue ~= nil and campaign.active_dialogue.finished then
        campaign.active_dialogue = nil
        campaign:advance_node()
    end
end

---@param campaign Campaign
---@param input InputContext
local function text_input_update(campaign, input)
    campaign.dialogue_manager:update(input)
    if campaign.active_dialogue ~= nil and campaign.active_dialogue.finished then
        campaign.active_dialogue = nil
    end
    campaign.menu_manager:update(input)
end

---@type table<CampaignNodeType, CampaignNodeHandler>
local HANDLERS = {

    -- ── Logic-only / auto-advance ────────────────────────────────────────

    jump = {
        enter = function(campaign, node)
            ---@cast node JumpNode
            campaign:jump_to_node(node.next_node)
        end,
    },

    detour = {
        enter = function(campaign, node)
            ---@cast node DetourNode
            table.insert(campaign.return_stack, {
                node_id = campaign.current_node.node_id,
                node_step = campaign.current_node.node_step + 1,
            })
            campaign:jump_to_node(node.target)
        end,
    },

    set_memory = {
        enter = function(campaign, node)
            ---@cast node SetMemoryNode
            campaign.campaign_state:set(node.key, campaign_state.text(node.value))
            campaign:advance_node()
        end,
    },

    set_memory_list = {
        enter = function(campaign, node)
            ---@cast node SetMemoryListNode
            campaign.campaign_state:set(node.key, campaign_state.list(node.values))
            campaign:advance_node()
        end,
    },

    new_page = {
        enter = function(campaign)
            campaign.page_flip_animator:begin_flip("forward", function()
                campaign.campaign_page:clear_page()
                campaign:advance_node()
            end)
        end,
    },

    roster_add = {
        enter = function(campaign, node)
            ---@cast node RosterAddNode
            local created = campaign.character_manager:generate_character(
                node.template,
                node.tags or {}
            )
            campaign.character_manager:persist_player(created)
            campaign.stats_service:record_recruitment(created.id, campaign.campaign_page.chapter_number)
            campaign:advance_node()
        end,
    },

    advance = {
        enter = function(campaign)
            campaign:advance_node()
        end,
    },

    delete_file = {
        enter = function(campaign)
            if campaign.save_name == nil then
                log.debug("No save file configured, skipping delete_file")
            else
                log.debug("Deleting save file: ", campaign.save_name)
                save_system.delete(campaign.save_name)
            end
            campaign:advance_node()
        end,
    },

    exit_campaign = {
        enter = function(campaign)
            campaign.event_writer:emit("GAME_EXIT_CAMPAIGN", {})
        end,
    },

    -- ── Rendered + dialogue confirm ──────────────────────────────────────

    chapter_header = {
        enter = function(campaign, node)
            ---@cast node ChapterHeader
            campaign.campaign_page:add_chapter_header(node.text, node.chapter_number)
            campaign.active_dialogue = campaign.dialogue_manager:create_dialogue(
                { "deleteme" }, -- TODO: this breaks if empty
                { auto_advance = false },
                {}
            )
        end,
        exit = function(campaign)
            campaign.campaign_page:clear_chapter_header()
            campaign.page_flip_animator:begin_flip("forward", function() end)
        end,
        update = dialogue_update,
    },

    text = {
        enter = function(campaign, node)
            ---@cast node CampaignTextNode
            local map = campaign.campaign_state:get_as_map()
            for k, v in pairs(campaign.stats_service:get_as_map()) do map[k] = v end
            campaign.active_dialogue = campaign.dialogue_manager:create_dialogue(
                { node.text },
                { can_skip = true, auto_advance = false },
                map
            )
            campaign.campaign_page:add_text_line(campaign.active_dialogue)
        end,
        exit = function(campaign)
            campaign.campaign_page:finish_text()
        end,
        update = dialogue_update,
    },

    save_game = {
        enter = function(campaign)
            if campaign.save_name == nil then
                log.debug("No save file configured, skipping save_game")
                campaign:advance_node()
            else
                local save_data = {
                    character_id_generator = campaign.character_manager.id_generator,
                    campaign_id = campaign.campaign_id,
                    campaign_node_id = campaign.current_node.node_id,
                    campaign_node_step = campaign.current_node.node_step + 1,
                    campaign_state = campaign.campaign_state,
                    roster = campaign.character_manager:get_player_roster(),
                    stats = campaign.stats_service.campaign_results,
                    campaign_config = campaign.campaign_config,
                    campaign_seed = campaign.campaign_seed,
                    campaign_rng_state = campaign.campaign_rng:get_state(),
                }
                save_system.save(campaign.save_name, save_data)
                campaign.active_dialogue = campaign.dialogue_manager:create_dialogue(
                    { "Progress saved." },
                    { can_skip = true, auto_advance = false },
                    campaign.campaign_state:get_as_map()
                )
                campaign.campaign_page:add_text_line(campaign.active_dialogue)
            end
        end,
        update = dialogue_update,
    },

    -- ── Rendered + menu interaction ──────────────────────────────────────

    character_customizer = {
        enter = function(campaign, node)
            ---@cast node CharacterCustomizerNode
            campaign.active_dialogue = campaign.dialogue_manager:create_dialogue(
                { "Customize your hero!" },
                { can_skip = true },
                campaign.campaign_state:get_as_map()
            )
            campaign.customized_character = campaign.character_manager:generate_character(
                "character_customizer_template", { "hero" }
            )
            campaign.campaign_menu_context.character_appearance = campaign.customized_character.appearance
            if node.name_key then
                campaign.customized_character.name = campaign.campaign_state:get(node.name_key).text
            end
            campaign.campaign_page:add_character_customization_menu(
                campaign.customized_character,
                node.key,
                campaign.idle_animation
            )
            campaign.menu_manager:set_menu("MENU_CUSTOMIZE_CHARACTER")
        end,
        exit = function(campaign, node)
            ---@cast node CharacterCustomizerNode
            campaign.character_manager:persist_player(campaign.customized_character)
            campaign.campaign_state:set(
                node.key,
                campaign_state.character(campaign.customized_character.id)
            )
            campaign.customized_character = nil
            campaign.menu_manager:clear_menu()
        end,
        update = function(campaign, input)
            campaign.menu_manager:update(input)
        end,
    },

    text_input = {
        enter = function(campaign, node)
            ---@cast node TextInputNode
            local key = node.key
            local mem = campaign.campaign_state:get_as_map()
            campaign.menu_manager:set_menu("MENU_TEXT_INPUT")
            local memory_map = setmetatable({}, {
                __index = function(_, k)
                    if mem[k] then return mem[k] end
                    if k == key then
                        local ctx = campaign.menu_manager.menu_ctx --[[@as KeyboardMenuContext?]]
                        if ctx then return ctx.keyboard_content end
                    end
                end
            })
            campaign.active_dialogue = campaign.dialogue_manager:create_dialogue(
                { node.text },
                { can_skip = true },
                memory_map,
                true
            )
            campaign.campaign_page:add_text_input_menu(key, campaign.active_dialogue)
            -- Weird hack to stop one (one still remains) "z" slipping into text entry
            -- todo: get a real solution that addresses all of the z's
            readtext(true)
        end,
        exit = function(campaign, node)
            ---@cast node TextInputNode
            campaign.campaign_state:set(
                node.key,
                campaign_state.text(campaign.text_input)
            )
            campaign.text_input = nil
            campaign.campaign_page:pop()
            campaign.campaign_page:pop()
            local dialogue = campaign.dialogue_manager:create_dialogue(
                { node.text },
                { can_skip = true },
                campaign.campaign_state:get_as_map(),
                true
            )
            dialogue.characters_rendered = 99999
            campaign.campaign_page:add_text_line(dialogue)
        end,
        update = text_input_update,
    },

    select_option = {
        enter = function(campaign, node)
            ---@cast node SelectOptionNode
            campaign.campaign_menu_context.selection_options = node.options
            campaign.menu_manager:set_menu("MENU_SELECT_OPTION")
            campaign.campaign_page:add_select_option_menu(node.options)
        end,
        exit = function(campaign, node)
            ---@cast node SelectOptionNode
            campaign.campaign_state:set(node.memory_key, campaign_state.text(campaign.selected_option))
            campaign.selected_option = nil
            campaign.menu_manager:clear_menu()
            campaign.campaign_page:pop()
        end,
        update = function(campaign, input)
            campaign.menu_manager:update(input)
        end,
    },

    -- ── Battle (event-driven; only enter is needed) ──────────────────────

    battle = {
        enter = function(campaign, node)
            ---@cast node BattleNode
            campaign.campaign_page:clear_page()
            campaign.battle_count = campaign.battle_count + 1
            -- Derive a deterministic battle-level seed and attach to rng_context.
            local battle_seed = campaign.campaign_seed * 31 + campaign.battle_count
            campaign.rng_context.battle_rng = random.new(battle_seed)
            campaign.battle_manager = battle_manager_module.new(
                campaign.battle_count,
                node.battle_id,
                campaign.campaign_config,
                campaign.rng_context,
                campaign.battle_config,
                campaign.game_data,
                campaign.character_manager,
                campaign.battle_services_bundle.task_manager,
                campaign.battle_services_bundle.animation_manager,
                campaign.battle_services_bundle.event_bus,
                campaign.music_player,
                campaign.ui_context,
                campaign.input_service
            )
        end,
        update = function(campaign, input)
            campaign.battle_manager:update(input)
        end,
    },

    -- ── Game results (advance-style with custom rendering) ───────────────

    game_results = {
        enter = function(campaign)
            local results = campaign.stats_service.campaign_results

            -- Build chapter display pages
            local chapter_pages = {}
            for i, chapter_result in pairs(results.chapter_results) do
                local units_lost_names = {}
                for _, death in ipairs(chapter_result.units_lost) do
                    if campaign.character_manager:is_player(death.unit_id) then
                        local char = campaign.character_manager:get_character(death.unit_id)
                        table.insert(units_lost_names, char and char.name or "Unknown")
                    end
                end
                chapter_pages[i] = {
                    chapter_number = i,
                    battle_id = chapter_result.battle_id,
                    result = chapter_result.result,
                    turns_taken = chapter_result.turns_taken,
                    units_lost_names = units_lost_names,
                }
            end

            -- Build unit display pages
            local full_roster = campaign.character_manager:get_full_roster()
            local unit_pages = {}
            for _, unit in ipairs(full_roster) do
                local kills = 0
                for _, chapter_result in pairs(results.chapter_results) do
                    for _, death in ipairs(chapter_result.units_lost) do
                        if death.attacker_id == unit.id then
                            kills = kills + 1
                        end
                    end
                end
                local drawable = character.create_drawable_unit(
                    unit, "player", character.facing.of("left")
                )
                drawable.animation_data = campaign.idle_animation
                table.insert(unit_pages, {
                    drawable = drawable,
                    name = unit.name,
                    chapter_recruited = results.chapter_recruited[unit.id],
                    combats = results.unit_combats[unit.id] or 0,
                    kills = kills,
                })
            end

            campaign.campaign_page:add_game_results(results, chapter_pages, unit_pages)
        end,
        update = function(campaign, input)
            if not input.actions["BUTTON_A"].pressed then return end
            local node = campaign.campaign_page.nodes[#campaign.campaign_page.nodes]
            ---@cast node RenderedGameResults
            if node.section == "chapters" then
                if node.page < #node.chapter_pages then
                    node.page = node.page + 1
                    campaign.campaign_page.campaign_revision = campaign.campaign_page.campaign_revision + 1
                elseif #node.unit_pages > 0 then
                    node.section = "units"
                    node.page = 1
                    campaign.campaign_page.campaign_revision = campaign.campaign_page.campaign_revision + 1
                else
                    campaign:advance_node()
                end
            else
                if node.page < #node.unit_pages then
                    node.page = node.page + 1
                    campaign.campaign_page.campaign_revision = campaign.campaign_page.campaign_revision + 1
                else
                    campaign:advance_node()
                end
            end
        end,
    },
}

return HANDLERS
