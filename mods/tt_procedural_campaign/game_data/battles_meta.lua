-- Static metadata about each encounter template.
--
-- battles_meta[template_id] = BattleMetaEntry
--
-- Used by update_recruitment_quota to determine which recruitment archetype
-- types to roll for a given encounter. Templates absent from this table
-- trigger the post-battle wanderer fallback instead.

---@class BattleMetaEntry
---@field recruitment_archetypes string[] Archetype type IDs eligible for recruitment in this template.

---@type table<string, BattleMetaEntry>
local battles_meta = {
    skirmish = {
        recruitment_archetypes = { "turncoat_enemy" },
    },
    abandoned_fortress_seize = {
        recruitment_archetypes = {},
    },
}

return battles_meta
