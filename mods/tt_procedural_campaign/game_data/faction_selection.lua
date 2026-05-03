local campaign_state_mod = include("src/tactics/campaign/campaign_state.lua")

--- Compute adjusted selection weights from base pool, appearance counts, and bias.
--- prefer_novel  multiplies each base weight by (max_count - count + 1),
---   favouring factions that have appeared fewer times.
--- prefer_dominant multiplies each base weight by (count + 1),
---   favouring factions that have appeared more often.
---@param faction_pool table<string, integer>
---@param counts table<string, integer> Appearance count per faction ID; missing keys default to 0.
---@param bias "prefer_novel"|"prefer_dominant"
---@return table<string, integer>
local function compute_weights(faction_pool, counts, bias)
    local max_count = 0
    for id, _ in pairs(faction_pool) do
        local c = counts[id] or 0
        if c > max_count then max_count = c end
    end
    local weights = {}
    for id, base in pairs(faction_pool) do
        local c = counts[id] or 0
        if bias == "prefer_novel" then
            weights[id] = base * (max_count - c + 1)
        else
            weights[id] = base * (c + 1)
        end
    end
    return weights
end

--- Pick one faction ID from `weights` using a single RNG roll.
--- Candidates are sorted by ID before selection so results are deterministic
--- regardless of table iteration order.
---@param rng RngInstance
---@param weights table<string, integer>
---@return string
local function weighted_pick(rng, weights)
    local total = 0
    local candidates = {}
    for id, w in pairs(weights) do
        total = total + w
        table.insert(candidates, { id = id, weight = w })
    end

    -- TODO: this can be non-deterministic without sorting
    local roll = rng:rndi(total)
    local cumulative = 0
    for _, c in ipairs(candidates) do
        cumulative = cumulative + c.weight
        if roll < cumulative then
            return c.id
        end
    end
    return candidates[#candidates].id
end

--- Select a faction for the next battle and update faction_appearance_counts in memory.
--- Reads current counts from campaign_state, applies archetype bias to compute weights,
--- picks a faction via one campaign_rng roll, then writes the updated counts back.
---@param archetype ArchetypeDefinition
---@param mem CampaignMemory
---@param campaign_rng RngInstance
---@return string faction_id
local function select_faction(archetype, mem, campaign_rng)
    local counts = {}
    local counts_entry = mem:get("faction_appearance_counts")
    if counts_entry then
        ---@cast counts_entry MapMemoryEntry
        for id, v in pairs(counts_entry.entries) do
            counts[id] = tonumber(v) or 0
        end
    end

    local weights  = compute_weights(archetype.faction_pool, counts, archetype.bias)
    local selected = weighted_pick(campaign_rng, weights)

    counts[selected] = (counts[selected] or 0) + 1
    local new_entries = {}
    for id, n in pairs(counts) do
        new_entries[id] = tostring(n)
    end
    mem:set("faction_appearance_counts", campaign_state_mod.map(new_entries))

    return selected
end

return {
    select_faction  = select_faction,
    compute_weights = compute_weights,
}
