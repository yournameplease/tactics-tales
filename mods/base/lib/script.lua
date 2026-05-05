---@class ScriptBuilder
---@field trigger table
---@field effects table[]
---@field one_shot boolean
---@field tags? string[]
local ScriptBuilder = {}
local script_builder = {}
ScriptBuilder.__index = ScriptBuilder

local script = {}
script.unit = {}

---@param trigger ScriptTrigger
---@return ScriptBuilder
function script_builder.new(trigger)
    local self = setmetatable({
        trigger = trigger,
        effects = {},
        one_shot = false,
    }, ScriptBuilder)

    return self
end

-- script effects

---@param units UnitSpawnData[]
---@param animation string?
---@return ScriptBuilder
function ScriptBuilder:then_spawn_units(units, animation)
    add(self.effects, {
        type = "spawn_units",
        units = units,
        animation = animation,
        blocked_behavior = "prevent"
    })
    return self
end

---@param units UnitSelector
---@return ScriptBuilder
function ScriptBuilder:then_despawn_units(units)
    add(self.effects, {
        type = "despawn_units",
        units = units
    })
    return self
end

---@param unit UnitSelector
---@param text string[]
---@return ScriptBuilder
function ScriptBuilder:then_dialogue(unit, text)
    add(self.effects, {
        type = "dialogue",
        unit = unit,
        text = text
    })
    return self
end

---@param unit_selector UnitSelector
---@param new_ai UnitAI?
---@param new_side Side?
---@return ScriptBuilder
function ScriptBuilder:then_modify_units(
    unit_selector,
    new_ai,
    new_side
)
    add(self.effects, {
        type = "modify_units",
        unit_selector = unit_selector,
        new_ai = new_ai,
        new_side = new_side,
    })
    return self
end

---@param unit_selector UnitSelector
---@param new_side Side
---@return ScriptBuilder
function ScriptBuilder:then_change_side(
    unit_selector,
    new_side
)
    return self:then_modify_units(unit_selector, nil, new_side)
end

---@param unit_selector UnitSelector
---@param new_ai UnitAI
---@return ScriptBuilder
function ScriptBuilder:then_change_ai(
    unit_selector,
    new_ai
)
    return self:then_modify_units(unit_selector, new_ai, nil)
end

---@param enabled boolean
---@return ScriptBuilder
function ScriptBuilder:then_set_tutorial(
    enabled
)
    add(self.effects, {
        type = "set_tutorial_mode",
        enabled = enabled,
    })
    return self
end

---@param unit_selector UnitSelector
---@return ScriptBuilder
function ScriptBuilder:then_recruit_unit(
    unit_selector
)
    add(self.effects, {
        type = "recruit_units",
        unit_selector = unit_selector,
    })
    return self
end

---@param tile_label string
---@param new_terrain table<TerrainLocation, integer>
---@return ScriptBuilder
function ScriptBuilder:then_modify_terrain(
    tile_label,
    new_terrain
)
    add(self.effects, {
        type = "modify_terrain",
        tile_label = tile_label,
        new_terrain = new_terrain
    })
    return self
end

---@param sound_id string
---@return ScriptBuilder
function ScriptBuilder:then_play_sound(
    sound_id
)
    add(self.effects, {
        type = "play_sound",
        sound_id = sound_id,
    })
    return self
end

---@param music_id string
---@return ScriptBuilder
function ScriptBuilder:then_play_music(
    music_id
)
    add(self.effects, {
        type = "play_music",
        music_id = music_id,
        music_type = "jingle",
    })
    return self
end

---@return ScriptBuilder
function ScriptBuilder:then_resume_music()
    add(self.effects, {
        type = "play_music",
    })
    return self
end

---@param tag string
---@return ScriptBuilder
function ScriptBuilder:then_remove_scripts(
    tag
)
    add(self.effects, {
        type = "remove_script",
        tag = tag,
    })
    return self
end

---@return ScriptBuilder
function ScriptBuilder:as_one_shot()
    self.one_shot = true
    return self
end

-- script triggers

---@param turn integer
---@param phase TurnTriggerTime
---@param repeating integer?
---@return ScriptBuilder
function script.on_turn(turn, phase, repeating)
    return script_builder.new({
        type = "turn",
        turn = turn,
        repeating = repeating,
        phase = phase,
    })
end

---@param unit_label string
---@return ScriptBuilder
function script.when_unit_dies(unit_label)
    return script_builder.new({
        type = "unit_death",
        unit_label = unit_label,
    })
end

---@param unit_specifier UnitSpecifier
---@param text string
---@return ScriptBuilder
function script.on_unit_interaction(unit_specifier, text)
    return script_builder.new({
        type = "unit_interaction",
        unit_specifier = unit_specifier,
        interaction_text = text,
    })
end

---@param unit_tag string
---@return ScriptBuilder
function script.on_talk(unit_tag)
    return script.on_unit_interaction(
        {
            type = "tag_lookup",
            tag = unit_tag,
        },
        "Talk"
    )
end

---@param tile_tag string
---@param text string
---@return ScriptBuilder
function script.on_tile_interaction(tile_tag, text)
    return script_builder.new({
        type = "tile_interaction",
        tile_specifier = {
            type = "tag_lookup",
            tag = tile_tag,
        },
        interaction_text = text,
        interaction_distance = "on",
    })
end

---@param attacker_tag? string
---@param defender_tag? string
---@return ScriptBuilder
function script.before_combat(attacker_tag, defender_tag)
    return script_builder.new({
        type = "before_combat",
        attacker_tag = attacker_tag,
        defender_tag = defender_tag,
    })
end

---@param attacker_tag? string
---@param defender_tag? string
---@return ScriptBuilder
function script.before_counterattack(attacker_tag, defender_tag)
    return script_builder.new({
        type = "before_counterattack",
        attacker_tag = attacker_tag,
        defender_tag = defender_tag,
    })
end

---@param tile_tag string
---@param text string
---@return ScriptBuilder
function script.on_adjacent_tile_interaction(tile_tag, text)
    return script_builder.new({
        type = "tile_interaction",
        tile_specifier = {
            type = "tag_lookup",
            tag = tile_tag,
        },
        interaction_text = text,
        interaction_distance = "adjacent",
    })
end

-- helpers

---@param unit_tag string
---@return UnitSelector
function script.unit.tagged(unit_tag)
    return {
        type = "tag_lookup",
        tag = unit_tag,
    }
end

---@return UnitSelector
function script.unit.source()
    return {
        type = "trigger_source",
    }
end

---@return UnitSelector
function script.unit.target()
    return {
        type = "trigger_target",
    }
end

-- other

---@param tags string[]
---@return ScriptBuilder
function ScriptBuilder:with_tags(tags)
    self.tags = tags
    return self
end

return {
    script = script
}
