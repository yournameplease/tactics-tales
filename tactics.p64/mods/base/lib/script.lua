local ScriptBuilder = {}
local script_builder = {}
ScriptBuilder.__index = ScriptBuilder

local script = {}
script.unit = {}

function script_builder.new(trigger)
  local self = setmetatable({
    trigger = trigger,
    effects = {},
    one_shot = false,
  }, ScriptBuilder)

  return self
end

-- script effects

function ScriptBuilder:then_spawn_units(players, enemies, animation)
	add(self.effects, {
		type = "spawn_units",
		players = players,
		enemies = enemies,
		animation = animation,
		blocked_behavior = "prevent"
	})
	return self
end
  
function ScriptBuilder:then_spawn_players(players, animation)
	return self:then_spawn_units(players, {}, animation)
end
  
function ScriptBuilder:then_spawn_enemies(enemies, animation)
	return self:then_spawn_units({}, enemies, animation)
end

function ScriptBuilder:then_despawn_units(units, text)
	add(self.effects, {
		type = "despawn_units",
		units = units
	})
	return self
end

function ScriptBuilder:then_dialogue(unit, text)
	add(self.effects, {
		type = "dialogue",
		unit = unit,
		text = text
	})
	return self
end

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

function ScriptBuilder:then_change_side(
    unit_selector,
    new_side
)
    return self:then_modify_units(unit_selector, nil, new_side)
end

function ScriptBuilder:then_change_ai(
    unit_selector,
    new_ai
)
    return self:then_modify_units(unit_selector, new_ai, nil)
end

function ScriptBuilder:then_recruit_unit(
    unit_selector
)
	add(self.effects, {
		type = "recruit_units",
		unit_selector = unit_selector,
	})
	return self
end

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

function ScriptBuilder:then_play_sound(
	sound_id
)
	add(self.effects, {
		type = "play_sound",
		sound_id = sound_id,
	})
	return self
end

function ScriptBuilder:then_play_music(
	music_id
)
	add(self.effects, {
		type = "play_music",
		music_id = music_id,
	})
	return self
end

function ScriptBuilder:as_one_shot()
	self.one_shot = true
	return self
end

-- script triggers

function script.on_turn(turn, phase, repeating)
	return script_builder.new({
		type = "turn",
		turn = turn,
		repeating = repeating,
		phase = phase,
	})
end

function script.when_unit_dies(unit_label)
	return script_builder.new({
		type = "unit_death",
		unit_label = unit_label,
	})
end

function script.on_unit_interaction(unit_specifier, text)
  return script_builder.new({
      type = "unit_interaction",
      unit_specifier = unit_specifier,
      interaction_text = text,
  })
end

function script.on_talk(unit_tag)
  return script.on_unit_interaction(
      {
          type = "tag_lookup",
          tag = unit_tag,
      },
      "Talk"
  )
end

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

function script.unit.tagged(unit_tag)
		return {
		    type = "tag_lookup",
		    tag = unit_tag,
		}
end

function script.unit.source()
		return {
		    type = "trigger_source",
		}
end

function script.unit.target()
		return {
		    type = "trigger_target",
		}
end


return {
  script = script
}
