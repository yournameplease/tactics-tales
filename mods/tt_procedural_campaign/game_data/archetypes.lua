-- Archetype definitions for the procedural campaign mod.
--
-- An archetype shapes the player's entire run: it dictates the sequence of
-- encounters (beats vs. filler), the pool of filler encounters and their
-- relative weights, and how quickly the player recruits allies.
--
-- Data shape
-- ----------
--   ArchetypeDefinition
--     .name            string            Display name used in the selection menu.
--     .description     string            Description used in the selection menu.
--     .slots           ArchetypeSlot[]   Ordered sequence of battle slots for the run.
--     .filler_pool     table<string,int> Encounter template IDs → relative weights.
--                                        Used for every filler slot unless overridden.
--     .recruitment_rate number           Expected number of recruitable units per chapter.
--
--   ArchetypeSlot
--     .type          "beat"|"filler"   "beat" = scripted encounter; "filler" = drawn
--                                       from the weighted pool at run-time.
--     .beat_id?      string            Required when type == "beat"; identifies the
--                                       scripted encounter template to use.
--     .pool_override? table<string,int> Per-slot weight overrides that replace the
--                                       archetype-level filler_pool for this slot only.

---@class ArchetypeSlot
---@field type "beat"|"filler"
---@field beat_id? string Template ID used when type == "beat".
---@field pool_override? table<string, integer> Per-slot filler weight overrides.
---@field forced_join? string Character template ID to force-add after the battle (no prompt, no quota cost).

---@class ArchetypeDefinition
---@field id string Unique identifier used for memory storage and lookup.
---@field name string Display name for the archetype selection screen.
---@field description string Description shown on the archetype selection screen.
---@field slots ArchetypeSlot[] Ordered sequence of battle slots for the run.
---@field filler_pool table<string, integer> Weighted pool of filler encounter template IDs.
---@field recruitment_rate number Expected number of recruitable units per chapter.
---@field faction_pool table<string, integer> Weighted pool of eligible faction IDs for enemy selection.
---@field bias "prefer_novel"|"prefer_dominant" How appearance counts skew faction weights.
---@field wanderer_pool string[] Flat list of character template IDs for neutral recruit and post-battle wanderer fallback.

-- ---------------------------------------------------------------------------
-- Worked example: the "Warband" archetype
--
-- A balanced run of 6 battles. The first and last are scripted beats; the
-- middle four draw from the filler pool with equal weight except that slot 3
-- heavily favours the "skirmish" template.
-- ---------------------------------------------------------------------------

---@type ArchetypeDefinition[]
local archetype_list = {
    -- {
    --     id               = "seize_run",
    --     name             = "Seize Run",
    --     description      = "Three seize battles in a row. Used to exercise the seize layout through the full campaign loop.",
    --     slots            = {
    --         { type = "beat", beat_id = "abandoned_fortress_seize" },
    --         { type = "beat", beat_id = "abandoned_fortress_seize" },
    --         { type = "beat", beat_id = "abandoned_fortress_seize" },
    --     },
    --     filler_pool      = { abandoned_fortress_seize = 1 },
    --     recruitment_rate = 1,
    --     faction_pool     = { bandits = 1 },
    --     bias             = "prefer_novel",
    --     wanderer_pool    = { "bandit_goon" },
    -- },

    {
        id               = "procedural_castle",
        name             = "Procedural Castle",
        description      = "A single procedurally generated castle battle.",

        slots            = {
            { type = "beat", beat_id = "procedural_castle" },
        },

        filler_pool      = { "procedural_castle" },
        recruitment_rate = 0,

        faction_pool     = { bandits = 1, cultists = 1, militia = 1 },
        bias             = "prefer_novel",

        wanderer_pool    = { "bandit_goon" },
    },

    {
        id               = "warband",
        name             = "Royal Reclaimer",
        description      = "A classic fantasy tactics story.",

        slots            = {
            { type = "beat",   beat_id = "castle_escape" },
            { type = "filler" },
            { type = "filler" },
            { type = "filler" },
            -- { type = "beat",   beat_id = "final_siege" },
        },

        -- filler_pool      = {
        --     -- skirmish       = 2,
        --     -- ambush         = 2,
        --     -- escort         = 1,
        --     -- hold_the_line  = 1,
        --     village_overrun = 1,
        -- },
        filler_pool = {
            "village_overrun",
            "cavern_fortress"
        },

        recruitment_rate = 2,

        faction_pool     = { bandits = 1, cultists = 1, militia = 1 },
        bias             = "prefer_novel",

        wanderer_pool    = { "bandit_goon", "militia_spearman" },
    },
}

---@type table<string, ArchetypeDefinition>
local archetypes_by_id = {}
for _, def in ipairs(archetype_list) do
    archetypes_by_id[def.id] = def
end

return { list = archetype_list, by_id = archetypes_by_id }
