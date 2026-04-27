local factions_mod = include("mods/tt_procedural_story/game_data/factions.lua")
local factions_data = factions_mod.factions
local resolve_slot  = factions_mod.resolve_slot

local character_source = {}

function character_source.template(template)
    return { type = "template", template = template }
end

function character_source.player_roster()
    return { type = "player_roster" }
end

local objectives = {}

function objectives.rout()
    return { type = "rout", text = "Defeat all enemies" }
end

function objectives.tagged_unit_dies(tag)
    return { type = "tagged_unit_dies", tag = tag }
end

local ai <const> = {
    move_two      = { move = "two",      target_sides = { "player", "neutral" } },
    move_one      = { move = "one",      target_sides = { "player", "neutral" } },
    stationary    = { move = "zero",     target_sides = { "player", "neutral" } },
}

local function get_faction(story_config)
    local faction_id = story_config.memory and story_config.memory.faction_id
    return factions_data[faction_id] or factions_data["bandits"]
end

local function get_tier(story_config)
    return tonumber(story_config.memory and story_config.memory.base_difficulty) or 1
end

---@type ModBattlesModule
local battles = {
    ["skirmish"] = function(story_config)
        local faction = get_faction(story_config)
        local tier    = get_tier(story_config)
        return {
            map_id = "playground",
            music  = 0,
            tile_labels = {
                ["player_deployment"] = { 0x00, 0x01, 0x02, 0x03 },
                ["enemy_inf_a"]       = { 0x10 },
                ["enemy_inf_b"]       = { 0x11 },
                ["enemy_tank_a"]      = { 0x12 },
                ["enemy_cmdr"]        = { 0x13 },
            },
            victory_conditions = { objectives.rout() },
            failure_conditions = { objectives.tagged_unit_dies("hero") },
            units = {
                { side = "player", character_source = character_source.player_roster(), tile = "player_deployment" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),  ai = ai.move_two,   tile = "enemy_inf_a" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_infantry")),  ai = ai.move_two,   tile = "enemy_inf_b" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_tank")),      ai = ai.move_one,   tile = "enemy_tank_a" },
                { side = "enemy",  character_source = character_source.template(resolve_slot(faction, tier, "enemy_commander")), ai = ai.stationary, tile = "enemy_cmdr", tags = { "boss" } },
            },
            scripts = {},
        }
    end,
}

return battles
