-- Procedural story mod — story definitions.
--
-- Story memory key conventions
-- ----------------------------
-- All procedural run state lives in story memory so it is automatically
-- persisted by the save_game node and restored on load.  Keys use snake_case
-- string values (story memory stores everything as text entries).
--
--   archetype_id               — ID of the archetype chosen at run start.
--                                Written by the select_option node that opens
--                                the story.
--
--   story_seed                 — Integer seed (as string) used to initialise
--                                the procedural RNG for this run.  Written once
--                                at run start.
--
--   battle_index               — 1-based index of the next battle to play.
--                                Incremented after each battle completes.
--
--   base_difficulty            — Numeric difficulty level (as string).
--                                Derived from story config at run start.
--
--   faction_appearance_counts  — Map entry (MapMemoryEntry) tracking how many
--                                times each faction has been selected (id → count
--                                as string).  Written by select_faction each time
--                                choose_next_story_beat picks a faction.
--
--   recruitment_quota_credits  — Accumulated fractional recruitment credits
--                                (stored as a decimal string).  Credits >= 1
--                                guarantee at least one recruit offer.
--
--   quota_window_counter       — Number of battles elapsed in the current
--                                recruitment quota window.  Resets when the
--                                window closes.
--
--   used_encounter_templates   — Space-separated list of encounter template IDs
--                                used so far this run, for duplicate avoidance.

local archetypes = include("mods/tt_procedural_story/game_data/archetypes.lua")

-- Build the option list for the archetype selection node from the archetype
-- definitions table so that the story data stays in sync automatically.
local function archetype_options()
    local opts = {}
    for id, def in pairs(archetypes) do
        table.insert(opts, { id = id, name = def.name, description = def.description })
    end
    return opts
end

---@type ModStoriesModule
local stories = {
    data = {
        proc_story = {
            name        = "Procedural Story",
            description = "A procedurally generated run.",

            battle_config = { permadeath = true },

            starting_node = "archetype_select",

            nodes = {
                -- Player chooses an archetype; ID is stored in story memory.
                archetype_select = {
                    { type = "select_option",
                      memory_key = "archetype_id",
                      options    = archetype_options() },
                    { type = "exit_story" },
                },
            },
        },
    },
}

return stories
