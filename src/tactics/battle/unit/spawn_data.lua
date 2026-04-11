---@brief
--- Defines the data structures for spawning units in a battle.
--- This includes the character source, AI behavior, and initial tile placement.

---@alias UnitSpawnBlockedBehavior "prevent"|"spawn_nearby"

---@alias UnitSpawnAnimation "from_north"|"from_south"|"from_east"|"from_west"

---@alias CharacterSourceType "template"|"player_roster"

---@class CharacterSource Abstract base for character sources.
---@field type CharacterSourceType

---@class PlayerRosterSource : CharacterSource
---@field type "player_roster"

---@class CharacterTemplateSource : CharacterSource
---@field type "template"
---@field template string Name of the character template to use.

---@class UnitSpawnData
---@field character_source CharacterSource
---@field side Side Which team this unit belongs to.
---@field movement_side string Movement team identifier; defaults to side.
---@field ai UnitAI AI behavior definition for this unit.
---@field tile TileLabel Tile label identifying the spawn location.
---@field tags string[] Tags for this unit; spawn tile tag is added automatically.

return {}
