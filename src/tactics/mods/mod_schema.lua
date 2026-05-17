---@brief
--- Specification for game mods.
--- Note that reference fields may be provided by dependent mods as well.
--- Used for mod validation.
--- Certain segments of mod data, such as missions, primarily use factory functions
--- and are excluded from static schema checking

--- TODO: this was mostly AI generated, some cleanup is still needed

local s = require("src.tactics.validator.schema_definition")

local mod_content_spec = s.record({
    maps = s.optional(s.string()),
    missions = s.optional(s.string()),
    campaigns = s.optional(s.string()),
    characters = s.optional(s.string()),
    items = s.optional(s.string()),
    skills = s.optional(s.string()),
    chunks = s.optional(s.string()),
    gfx = s.optional(s.list(s.string())),
    campaign_select = s.optional(s.list(s.string())),
    default_campaign = s.optional(s.string()),
})

local maps_spec = s.dictionary(
    s.string(),
    s.record({
        type = s.string(),
        file = s.optional(s.string()),
    })
)

-- Schemas for `items`
local item_spec_record = s.record({
    name = s.string(),
    type = s.string(),
    slots = s.integer(),
    equip_slot = s.string(),

    equipment_effects = s.optional(s.list(s.record({
        type = s.string(),
        amount = s.integer(),
        defense_type = s.optional(s.string()),
        avoid_type = s.optional(s.string()),
    }))),
    appearance_overrides = s.optional(s.dictionary(s.string(), s.string())),

    sprite_data = s.optional(s.record({
        sprite = s.integer(),
        anchor = s.record({ x = s.integer(), y = s.integer() }),
    })),

    weapon_definition = s.optional(s.record({
        name = s.string(),
        sprite = s.integer(),
        damage = s.integer(),
        accuracy = s.integer(),
        targeting = s.optional(s.record({
            get_selection_tiles = s.func(),
            get_targets_for_selection = s.func(),
            is_target_valid = s.func(),
            range_min = s.optional(s.integer()),
            range_max = s.optional(s.integer()),
        })),
        type = s.string(),
        body_type = s.string(),
        effects = s.optional(s.list(s.record({ type = s.string() }))),
    })),
})
local items_spec = s.dictionary(s.string(), item_spec_record)

-- Schemas for `skills`
local valid_effect_types = {
    heal=true, damage=true, hp_cost=true, debuff=true, buff=true,
    spawn=true, transfer_hp=true, drain_heal=true, siphon=true, refresh_action=true,
}

local skill_entry_spec = s.custom(function(skill)
    if type(skill) ~= "table" then
        return false, { "expected table, got " .. type(skill) }
    end
    local errors = {}
    if type(skill.name) ~= "string" then
        table.insert(errors, "name: required string")
    end
    if skill.targeting == nil then
        table.insert(errors, "targeting: required")
    end
    if type(skill.effects) ~= "table" or #skill.effects == 0 then
        table.insert(errors, "effects: required non-empty array")
    else
        for i, effect in ipairs(skill.effects) do
            if type(effect) ~= "table" then
                table.insert(errors, "effects[" .. i .. "]: expected table")
            elseif not valid_effect_types[effect.type] then
                table.insert(errors, "effects[" .. i .. "].type: unknown type " .. tostring(effect.type))
            end
        end
    end
    return #errors == 0, errors
end)
local skills_spec = s.dictionary(s.string(), skill_entry_spec)

-- Schemas for `characters`
local randomizer_options_spec = s.record({
    type = s.string(),
    -- `options` is a table that can be a list of strings or a dictionary of string to number.
    -- We are validating it as a generic table, as the schema system does not support unions.
    options = s.record({})
})

local character_template_spec = s.record({
    parent_template = s.optional(s.reference("characters")),
    movement = s.optional(s.integer()),
    hp_max = s.optional(s.integer()),
    item_loadout = s.optional(s.list(s.reference("items"))),
    skill_loadout = s.optional(s.list(s.reference("skills"))),
    head_options_m = s.optional(randomizer_options_spec),
    head_options_f = s.optional(randomizer_options_spec),
    headwear_options = s.optional(randomizer_options_spec),
    eyewear_options = s.optional(randomizer_options_spec),
    body_options = s.optional(randomizer_options_spec),
    gender_options = s.optional(randomizer_options_spec),
    skin_color_options = s.optional(randomizer_options_spec),
    hair_color_options = s.optional(randomizer_options_spec),
    beard_options = s.optional(randomizer_options_spec),
    eye_options = s.optional(randomizer_options_spec),
    hair_options_m = s.optional(randomizer_options_spec),
    hair_options_f = s.optional(randomizer_options_spec),
})
local characters_spec = s.dictionary(s.string(), character_template_spec)

local missions_spec = s.dictionary(s.string(), s.factory())

-- Campaign nodes can contain factory functions (CampaignNodeFactory), so deep
-- validation is not possible here. Accept any table, like missions_spec.
local campaigns_data_spec = s.dictionary(s.string(), s.record({}))

local campaigns_spec = s.record({
    data = campaigns_data_spec,
    default_campaign = s.reference("campaigns.data"),
    campaign_select = s.list(s.reference("campaigns.data")),
})

local game_data_schema = s.record({
    loaded_mods = s.dictionary(
        s.string(),
        s.boolean()
    ),
    maps = maps_spec,
    missions = missions_spec,
    campaigns = campaigns_spec,
    characters = characters_spec,
    items = items_spec,
    skills = skills_spec,
})

return {
    maps = maps_spec,
    missions = missions_spec,
    campaigns = campaigns_spec,
    characters = characters_spec,
    items = items_spec,
    skills = skills_spec,
    mod_content = mod_content_spec,
    final_schema = game_data_schema,
}
