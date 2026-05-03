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

---@type table<string, ArchetypeDefinition>
local archetypes = {
    warband = {
        name        = "Warband",
        description = "A balanced campaign: open with a scripted skirmish, close with a decisive siege, and fill the middle with varied encounters.",

        slots = {
            { type = "beat",   beat_id = "opening_skirmish", forced_join = "bandit_goon" },
            { type = "filler" },
            { type = "filler", pool_override = { skirmish = 3, ambush = 1 } },
            { type = "filler" },
            { type = "filler" },
            { type = "beat",   beat_id = "final_siege" },
        },

        filler_pool = {
            skirmish      = 2,
            ambush        = 2,
            escort        = 1,
            hold_the_line = 1,
        },

        recruitment_rate = 2,

        faction_pool     = { bandits = 1, cultists = 1, militia = 1 },
        bias             = "prefer_novel",

        wanderer_pool    = { "bandit_goon", "militia_spearman" },
    },
}

return archetypes
