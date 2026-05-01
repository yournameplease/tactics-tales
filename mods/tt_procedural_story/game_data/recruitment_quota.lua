local campaign_state_mod = include("src/tactics/campaign/campaign_state.lua")
local battles_meta     = include("mods/tt_procedural_story/game_data/battles_meta.lua")

--- Accumulate recruitment credits for this battle, roll pending recruit types,
--- and write the results back to story memory.
---
--- Credits carry a fractional remainder so that rates < 1 still produce recruits
--- over multiple battles. Spent credits are deducted (only the remainder is saved).
---
---@param archetype ArchetypeDefinition
---@param mem StoryMemory
---@param rng RngInstance
---@param template_id string Encounter template for this battle; used to look up eligible recruit types.
---@return string debug_text
local function update_recruitment_quota(archetype, mem, rng, template_id)
    local credits_entry = mem:get("recruitment_quota_credits")
    local credits = 0
    if credits_entry then
        ---@cast credits_entry TextMemoryEntry
        credits = tonumber(credits_entry.text) or 0
    end

    credits = credits + archetype.recruitment_rate
    local recruit_count = math.floor(credits)
    local remainder     = credits - recruit_count

    local pending      = {}
    local meta         = battles_meta[template_id]
    local archetype_types = meta and meta.recruitment_archetypes or {}
    if #archetype_types > 0 then
        for _ = 1, recruit_count do
            table.insert(pending, rng:choose_random_from_list(archetype_types))
        end
    end

    mem:set("recruitment_quota_credits", campaign_state_mod.text(tostring(remainder)))
    mem:set("pending_recruits", campaign_state_mod.list(pending))

    local types_str = #pending > 0 and table.concat(pending, ", ") or "none"
    return string.format("[quota] Added %s credits. %d recruit(s) pending: %s.",
        archetype.recruitment_rate, recruit_count, types_str)
end

return {
    update_recruitment_quota = update_recruitment_quota,
}
