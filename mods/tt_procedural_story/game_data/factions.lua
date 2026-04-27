---@type table<string, FactionDefinition>
local factions = {
    bandits = {
        name = "Bandits",
        tiers = {
            { enemy_infantry = "bandit_goon",  enemy_commander = "bandit_boss",        enemy_tank = "bandit_guard" },
            { enemy_infantry = "bandit_axe",   enemy_commander = "bandit_berzerker",   enemy_tank = "bandit_guard" },
        },
        fallbacks = { enemy_ranged = "enemy_infantry" },
    },
    cultists = {
        name = "Cultists",
        tiers = {
            { enemy_infantry = "cultist_goon",     enemy_commander = "cultist_boss", enemy_tank = "cultist_guard" },
            { enemy_infantry = "cultist_spearman", enemy_commander = "cultist_boss", enemy_tank = "cultist_guard" },
        },
        fallbacks = { enemy_ranged = "enemy_infantry" },
    },
    militia = {
        name = "Militia",
        tiers = {
            { enemy_infantry = "militia_spearman", enemy_commander = "militia_spear_captain", enemy_tank = "militia_armor", enemy_ranged = "militia_archer" },
            { enemy_infantry = "militia_sword",    enemy_commander = "militia_sword_captain", enemy_tank = "militia_armor", enemy_ranged = "militia_archer" },
        },
        fallbacks = { enemy_ranged = "enemy_infantry" },
    },
}

---@param faction FactionDefinition
---@param tier_index integer
---@param slot_tag FactionSlotTag
---@return string?
local function resolve_slot(faction, tier_index, slot_tag)
    local tier = faction.tiers[tier_index] or faction.tiers[#faction.tiers]
    local template = tier[slot_tag]
    if not template and faction.fallbacks then
        local fallback_slot = faction.fallbacks[slot_tag]
        if fallback_slot then
            template = tier[fallback_slot]
        end
    end
    return template
end

---@type FactionsModule
return {
    factions     = factions,
    resolve_slot = resolve_slot,
}
