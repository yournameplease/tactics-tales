---@brief
--- Defines the data structures for the battle scripting system.
--- Specifies the shape of triggers and their corresponding effects,
--- forming the basis for event-driven scenarios in battles.

-- selector: may depend on script context.  for effects
-- specifier: no context.  for triggers

---@alias UnitSelectorMode "trigger_source"|"trigger_target"|"tag_lookup"

---@class UnitSelector Abstract base for unit selectors.
---@field type UnitSelectorMode

---@class UnitSpecifier Abstract base for unit specifiers (no script context).
---@field type UnitSelectorMode

---@class TriggerSourceUnitSelector : UnitSelector
---@field type "trigger_source"

---@class TriggerTargetUnitSelector : UnitSelector
---@field type "trigger_target"

---@class TagLookupUnitSelector : UnitSelector
---@field type "tag_lookup"
---@field tag string Tag used to look up the target unit.

---@alias TileSelectorMode "static_point"|"tag_lookup"|"trigger_source"|"trigger_target"

---@class TileSelector Abstract base for tile selectors.
---@field type TileSelectorMode

---@class TileSpecifier Abstract base for tile specifiers (no script context).
---@field type TileSelectorMode

---@class StaticPointTileSpecifier : TileSpecifier
---@field type "static_point"
---@field point PointRecord Fixed tile coordinate.

---@class TagLookupTileSpecifier : TileSpecifier
---@field type "tag_lookup"
---@field tag string Tag used to look up the target tile.

---@class TriggerSourceTileSelector : TileSelector
---@field type "trigger_source"

---@class TriggerTargetTileSelector : TileSelector
---@field type "trigger_target"

---@alias ScriptTriggerType "turn"|"unit_death"|"unit_interaction"|"tile_interaction"

---@class ScriptTrigger Abstract base for script triggers.
---@field type ScriptTriggerType

---@alias TurnTriggerTimeOffset "before"|"after"

---@class TurnTriggerTime
---@field offset TurnTriggerTimeOffset Whether the trigger fires before or after the turn.
---@field side Side Which side's turn to trigger on.

---@class Turn : ScriptTrigger
---@field type "turn"
---@field turn integer Turn number to trigger on.
---@field repeating integer Repeat interval in turns (0 = no repeat).
---@field phase TurnTriggerTime When within the turn this trigger fires.

---@class UnitDeath : ScriptTrigger
---@field type "unit_death"
---@field unit_label string Label identifying the unit whose death triggers this script.

---@class UnitInteraction : ScriptTrigger
---@field type "unit_interaction"
---@field unit_specifier UnitSpecifier Identifies the unit that must be interacted with.
---@field interaction_text string Prompt text shown to the player.

---@class TileInteraction : ScriptTrigger
---@field type "tile_interaction"
---@field tile_specifier TileSpecifier Identifies the tile that must be interacted with.
---@field interaction_text string Prompt text shown to the player.
---@field interaction_distance TileDistance How close a unit must be to trigger the interaction.

---@alias ScriptEffectType "spawn_units"|"modify_units"|"recruit_units"|"modify_terrain"|"dialogue"|"despawn_units"|"play_sound"|"play_music"|"remove_script"|"set_tutorial_mode"

---@class ScriptEffect Abstract base for script effects.
---@field type ScriptEffectType

---@class SpawnUnits : ScriptEffect
---@field type "spawn_units"
---@field blocked_behavior UnitSpawnBlockedBehavior What to do when the spawn tile is occupied.
---@field animation UnitSpawnAnimation Direction from which units animate in.
---@field units UnitSpawnData[] Units to spawn.

---@class ModifyUnits : ScriptEffect
---@field type "modify_units"
---@field unit_selector UnitSelector Which units to modify.
---@field new_side Side New team to assign to the selected units.
---@field new_ai UnitAI New AI behavior to assign to the selected units.

---@class RecruitUnits : ScriptEffect
---@field type "recruit_units"
---@field unit_selector UnitSelector Which units to recruit to the player roster.

---@class ModifyTerrain : ScriptEffect
---@field type "modify_terrain"
---@field tile_label string Label identifying which tiles to modify.
---@field new_terrain table<TerrainLocation, integer> New tile indices keyed by terrain layer.

---@class Dialogue : ScriptEffect
---@field type "dialogue"
---@field unit UnitSelector Unit who is speaking the dialogue.
---@field text string[] Lines of dialogue text to display.

---@class DespawnUnits : ScriptEffect
---@field type "despawn_units"
---@field units UnitSelector Which units to remove from the map.

---@class PlaySound : ScriptEffect
---@field type "play_sound"
---@field sound_id string

---@alias MusicType "music"|"jingle"

---@class PlayMusic : ScriptEffect
---@field type "play_music"
---@field music_id string
---@field music_type MusicType Whether to play a looping track or a one-shot jingle.

---@class RemoveScript : ScriptEffect
---@field type "remove_script"
---@field tag string Tag identifying the script to remove.

---@class SetTutorialMode : ScriptEffect
---@field type "set_tutorial_mode"
---@field enabled boolean Whether to enable or disable tutorial mode.

---@class BattleScript
---@field id integer
---@field tags string[]
---@field trigger ScriptTrigger
---@field effects ScriptEffect[]
---@field one_shot boolean Whether this script should be removed after it fires.

return {}
