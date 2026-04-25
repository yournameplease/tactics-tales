-- Handlers access Story @field package fields; Story fields are package-scoped to
-- src/tactics/story/ but handlers live in the subdirectory handlers/.
---@diagnostic disable: invisible
local save_system = require("src.tactics.save.save_system")
local battle_manager_module = require("src.tactics.battle.battle_manager")
local story_memory = require("src.tactics.story.story_memory")
local drawable_character = require("src.tactics.story.drawable_character")
local character = require("src.tactics.character.object.character")

---@param story Story
---@param input InputContext
local function dialogue_update(story, input)
    story.dialogue_manager:update(input)
    if story.active_dialogue ~= nil and story.active_dialogue.finished then
        story.active_dialogue = nil
        story:advance_node()
    end
end

---@param story Story
---@param input InputContext
local function text_input_update(story, input)
    story.dialogue_manager:update(input)
    if story.active_dialogue ~= nil and story.active_dialogue.finished then
        story.active_dialogue = nil
    end
    story.menu_manager:update(input)
end

---@type table<StoryNodeType, StoryNodeHandler>
local HANDLERS = {

    -- ── Logic-only / auto-advance ────────────────────────────────────────

    jump = {
        enter = function(story, node)
            ---@cast node JumpNode
            story:jump_to_node(node.next_node)
        end,
    },

    set_memory = {
        enter = function(story, node)
            ---@cast node SetMemoryNode
            story.story_memory:set(node.key, story_memory.text(node.value))
            story:advance_node()
        end,
    },

    new_page = {
        enter = function(story)
            story.story_page:clear_page()
            story:advance_node()
        end,
    },

    roster_add = {
        enter = function(story, node)
            ---@cast node RosterAddNode
            local created = story.character_manager:generate_character(
                node.template,
                node.tags or {}
            )
            story.character_manager:persist_player(created)
            story.stats_service:record_recruitment(created.id, story.story_page.chapter_number)
            story:advance_node()
        end,
    },

    advance = {
        enter = function(story)
            story:advance_node()
        end,
    },

    delete_file = {
        enter = function(story)
            if story.save_name == nil then
                log.debug("No save file configured, skipping delete_file")
            else
                log.debug("Deleting save file: ", story.save_name)
                save_system.delete(story.save_name)
            end
            story:advance_node()
        end,
    },

    exit_story = {
        enter = function(story)
            story.event_writer:emit("GAME_EXIT_STORY", {})
        end,
    },

    -- ── Rendered + dialogue confirm ──────────────────────────────────────

    chapter_header = {
        enter = function(story, node)
            ---@cast node ChapterHeader
            story.story_page:add_chapter_header(node.text, node.chapter_number)
            story.active_dialogue = story.dialogue_manager:create_dialogue(
                {"deleteme"}, -- TODO: this breaks if empty
                { auto_advance = false },
                {}
            )
        end,
        exit = function(story)
            story.story_page:clear_chapter_header()
        end,
        update = dialogue_update,
    },

    text = {
        enter = function(story, node)
            ---@cast node StoryTextNode
            story.active_dialogue = story.dialogue_manager:create_dialogue(
                {node.text},
                { can_skip = true, auto_advance = false },
                story.story_memory:get_as_map()
            )
            story.story_page:add_text_line(story.active_dialogue)
        end,
        exit = function(story)
            story.story_page:finish_text()
        end,
        update = dialogue_update,
    },

    save_game = {
        enter = function(story)
            if story.save_name == nil then
                log.debug("No save file configured, skipping save_game")
                story:advance_node()
            else
                local save_data = {
                    character_id_generator = story.character_manager.id_generator,
                    story_id = story.story_id,
                    story_node_id = story.current_node.node_id,
                    story_node_step = story.current_node.node_step + 1,
                    story_memory = story.story_memory,
                    roster = story.character_manager:get_player_roster(),
                    stats = story.stats_service.story_results,
                }
                save_system.save(story.save_name, save_data)
                story.active_dialogue = story.dialogue_manager:create_dialogue(
                    {"Progress saved."},
                    { can_skip = true, auto_advance = false },
                    story.story_memory:get_as_map()
                )
                story.story_page:add_text_line(story.active_dialogue)
            end
        end,
        update = dialogue_update,
    },

    -- ── Rendered + menu interaction ──────────────────────────────────────

    character_customizer = {
        enter = function(story, node)
            ---@cast node CharacterCustomizerNode
            story.active_dialogue = story.dialogue_manager:create_dialogue(
                {"Customize your hero!"},
                { can_skip = true },
                story.story_memory:get_as_map()
            )
            story.customized_character = story.character_manager:generate_character(
                "character_customizer_template", {"hero"}
            )
            story.story_menu_context.character_appearance = story.customized_character.appearance
            if node.name_key then
                story.customized_character.name = story.story_memory:get(node.name_key).text
            end
            story.story_page:add_character_customization_menu(
                story.customized_character,
                node.key,
                story.idle_animation
            )
            story.menu_manager:set_menu("MENU_CUSTOMIZE_CHARACTER")
        end,
        exit = function(story, node)
            ---@cast node CharacterCustomizerNode
            story.character_manager:persist_player(story.customized_character)
            story.story_memory:set(
                node.key,
                story_memory.character(story.customized_character.id)
            )
            story.customized_character = nil
            story.menu_manager:clear_menu()
        end,
        update = function(story, input)
            story.menu_manager:update(input)
        end,
    },

    text_input = {
        enter = function(story, node)
            ---@cast node TextInputNode
            local key = node.key
            local mem = story.story_memory:get_as_map()
            story.menu_manager:set_menu("MENU_TEXT_INPUT")
            local memory_map = setmetatable({}, {
                __index = function(_, k)
                    if mem[k] then return mem[k] end
                    if k == key then
                        local ctx = story.menu_manager.menu_ctx --[[@as KeyboardMenuContext?]]
                        if ctx then return ctx.keyboard_content end
                    end
                end
            })
            story.active_dialogue = story.dialogue_manager:create_dialogue(
                {node.text},
                { can_skip = true },
                memory_map,
                true
            )
            story.story_page:add_text_input_menu(key, story.active_dialogue)
        end,
        exit = function(story, node)
            ---@cast node TextInputNode
            story.story_memory:set(
                node.key,
                story_memory.text(story.text_input)
            )
            story.text_input = nil
            story.story_page:pop()
            story.story_page:pop()
            local dialogue = story.dialogue_manager:create_dialogue(
                {node.text},
                { can_skip = true },
                story.story_memory:get_as_map(),
                true
            )
            dialogue.characters_rendered = 99999
            story.story_page:add_text_line(dialogue)
        end,
        update = text_input_update,
    },

    -- ── Battle (event-driven; only enter is needed) ──────────────────────

    battle = {
        enter = function(story, node)
            ---@cast node BattleNode
            story.story_page:clear_page()
            story.battle_count = story.battle_count + 1
            story.battle_manager = battle_manager_module.new(
                story.battle_count,
                node.battle_id,
                story.story_config,
                story.battle_config,
                story.game_data,
                story.character_manager,
                story.battle_services_bundle.task_manager,
                story.battle_services_bundle.animation_manager,
                story.battle_services_bundle.event_bus,
                story.music_player,
                story.ui_context
            )
        end,
        update = function(story, input)
            story.battle_manager:update(input)
        end,
    },

    -- ── Game results (advance-style with custom rendering) ───────────────

    game_results = {
        enter = function(story)
            local results = story.stats_service.story_results

            -- Build chapter display pages
            local chapter_pages = {}
            for i, chapter_result in pairs(results.chapter_results) do
                local units_lost_names = {}
                for _, death in ipairs(chapter_result.units_lost) do
                    if story.character_manager:is_player(death.unit_id) then
                        local char = story.character_manager:get_character(death.unit_id)
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
            local full_roster = story.character_manager:get_full_roster()
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
                local drawable = drawable_character.create_drawable_unit(
                    unit, "player", character.facing.of("left")
                )
                drawable.animation_data = story.idle_animation
                table.insert(unit_pages, {
                    drawable = drawable,
                    name = unit.name,
                    chapter_recruited = results.chapter_recruited[unit.id],
                    combats = results.unit_combats[unit.id] or 0,
                    kills = kills,
                })
            end

            story.story_page:add_game_results(results, chapter_pages, unit_pages)
        end,
        update = function(story, input)
            if not input.actions["BUTTON_A"].pressed then return end
            local node = story.story_page.nodes[#story.story_page.nodes]
            ---@cast node RenderedGameResults
            if node.section == "chapters" then
                if node.page < #node.chapter_pages then
                    node.page = node.page + 1
                    story.story_page.story_revision = story.story_page.story_revision + 1
                elseif #node.unit_pages > 0 then
                    node.section = "units"
                    node.page = 1
                    story.story_page.story_revision = story.story_page.story_revision + 1
                else
                    story:advance_node()
                end
            else
                if node.page < #node.unit_pages then
                    node.page = node.page + 1
                    story.story_page.story_revision = story.story_page.story_revision + 1
                else
                    story:advance_node()
                end
            end
        end,
    },
}

return HANDLERS
