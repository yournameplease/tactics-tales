-- Procedural story mod — story definitions.
--
-- Campaign memory key conventions
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
--                                Derived from campaign config at run start.
--
--   faction_appearance_counts  — Map entry (MapMemoryEntry) tracking how many
--                                times each faction has been selected (id → count
--                                as string).  Written by select_faction each time
--                                choose_next_campaign_beat picks a faction.
--
--   faction_id                 — Text entry holding the faction chosen for the
--                                current battle.  Written by select_faction before
--                                each battle and read by the skirmish battle factory.
--
--   recruitment_quota_credits  — Accumulated fractional recruitment credits
--                                (stored as a decimal string).  Credits >= 1
--                                guarantee at least one recruit offer.
--
--   pending_recruits           — List entry holding archetype type IDs for
--                                recruits generated this battle.  Written by
--                                update_recruitment_quota; cleared by
--                                auto_recruit_pending after each battle.

local archetypes_data    = include("mods/tt_procedural_campaign/game_data/archetypes.lua")
local faction_sel        = include("mods/tt_procedural_campaign/game_data/faction_selection.lua")
local recruitment        = include("mods/tt_procedural_campaign/game_data/recruitment_quota.lua")
local auto_rec           = include("mods/tt_procedural_campaign/game_data/auto_recruit.lua")
local forced_join_mod    = include("mods/tt_procedural_campaign/game_data/forced_join.lua")
local campaign_state_mod = include("src/tactics/campaign/campaign_state.lua")

-- Build the option list for the archetype selection node from the archetype
-- definitions table so that the story data stays in sync automatically.
local function archetype_options()
    local opts = {}
    for id, def in pairs(archetypes_data) do
        table.insert(opts, { id = id, name = def.name, description = def.description })
    end
    return opts
end

-- Read the selected archetype from memory; fall back to "warband" if not set.
local function get_archetype(sc)
    local entry = sc.memory and sc.memory:get("archetype_id")
    local id = entry and entry.text
    return archetypes_data[id] or archetypes_data["warband"]
end

-- Read the 1-based battle index from memory; defaults to 1.
local function get_battle_index(sc)
    local entry = sc.memory and sc.memory:get("battle_index")
    return tonumber(entry and entry.text) or 1
end

-- Resolve the encounter template ID for a given archetype slot.
-- Beat slots use their explicit beat_id; filler slots pick a key from the pool.
local function slot_template_id(archetype, slot, rng)
    if slot.type == "beat" then
        return slot.beat_id
    end
    local pool = slot.pool_override or archetype.filler_pool

    -- TODO: this can be non-deterministic with a map input
    return rng:choose_random_from_list(pool)
end

---@type ModStoriesModule
local stories = {
    data = {
        proc_campaign = {
            name          = "Procedural Campaign",
            description   = "A procedurally generated run.",

            battle_config = { permadeath = true },

            starting_node = "archetype_select",

            nodes         = {
                -- Player chooses an archetype; ID is stored in campaign memory.
                -- battle_index is initialised to 1 before the loop starts.
                archetype_select = {
                    {
                        type       = "select_option",
                        memory_key = "archetype_id",
                        options    = archetype_options()
                    },
                    { type = "set_memory", key = "battle_index",              value = "1" },
                    { type = "roster_add", template = "militia_spear_captain" },
                    { type = "roster_add", template = "militia_spearman" },
                    { type = "roster_add", template = "militia_archer" },
                    { type = "roster_add", template = "militia_armor" },
                    { type = "roster_add", template = "priest" },
                    { type = "roster_add", template = "mage" },
                    { type = "jump",       next_node = "battle_loop" },
                },

                -- Per-battle setup: quota → faction → battle.
                -- Each step is a factory so it executes with the live memory
                -- state at the moment it is entered.
                battle_loop = {
                    -- Step 1: accumulate credits and roll pending recruits.
                    -- Also writes current_battle_id so step 3 can read the resolved
                    -- template without re-rolling RNG for filler slots.
                    function(sc, rng)
                        local archetype = get_archetype(sc)
                        local idx       = get_battle_index(sc)
                        local slot      = archetype.slots[idx]
                        local template  = slot_template_id(archetype, slot, rng.campaign_rng)
                        sc.memory:set("current_battle_id", campaign_state_mod.text(template))
                        local text = recruitment.update_recruitment_quota(
                            archetype, sc.memory, rng.campaign_rng, template)
                        return { type = "text", text = text }
                    end,

                    -- Step 2: pick a faction and store it for the battle factory.
                    function(sc, rng)
                        local archetype  = get_archetype(sc)
                        local faction_id = faction_sel.select_faction(archetype, sc.memory, rng.campaign_rng)
                        sc.memory:set("faction_id", campaign_state_mod.text(faction_id))
                        return { type = "text", text = "[faction] Selected: " .. faction_id }
                    end,

                    -- Step 3: run the battle; both outcomes go to post_battle.
                    -- battle_id is read from memory (written by step 1) so filler
                    -- slots don't re-roll RNG.
                    function(sc, _)
                        local entry = sc.memory and sc.memory:get("current_battle_id")
                        local battle_id = (entry and entry.text) or "skirmish"
                        return {
                            type = "battle",
                            battle_id = battle_id,
                            next_node_victory = "post_battle",
                            next_node_failure = "post_battle"
                        }
                    end,
                },

                -- Post-battle cleanup: forced_join → auto_recruit → increment index → loop or exit.
                post_battle = {
                    -- Step 1: forced join if the slot declares one (no prompt, no quota cost).
                    function(sc, _)
                        local archetype = get_archetype(sc)
                        local idx       = get_battle_index(sc)
                        local slot      = archetype.slots[idx]
                        return forced_join_mod.forced_join_node(slot)
                    end,

                    -- Step 2: process pending recruits and clear the list.
                    function(sc, _)
                        local text = auto_rec.auto_recruit_pending(sc.memory)
                        return { type = "text", text = text }
                    end,

                    -- Step 3: increment battle_index; continue or exit.
                    function(sc, _)
                        local archetype = get_archetype(sc)
                        local idx       = get_battle_index(sc)
                        local new_idx   = idx + 1
                        sc.memory:set("battle_index", campaign_state_mod.text(tostring(new_idx)))
                        if new_idx > #archetype.slots then
                            return { type = "exit_campaign" }
                        else
                            return { type = "jump", next_node = "battle_loop" }
                        end
                    end,
                },
            },
        },
    },
}

return stories
