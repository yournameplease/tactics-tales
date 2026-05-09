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
---@field movement_side? string Movement team identifier; defaults to side.
---@field ai? UnitAI AI behavior definition for this unit.
---@field tile TileLabel Tile label identifying the spawn location.
---@field tags? string[] Tags for this unit; spawn tile tag is added automatically.

---@class SlotSpawnData
---@field character_source CharacterSource
---@field ai? UnitAI AI behavior definition for units at this slot.

---@class RectZone
---@field x integer Left tile column (inclusive).
---@field y integer Top tile row (inclusive).
---@field w integer Width in tiles.
---@field h integer Height in tiles.

---@class LayerSpawnData
---@field side Side Which team these units belong to.
---@field movement_side? string Movement team identifier; defaults to side.
---@field layer string Spawn group layer name (from map.spawn_groups).
---@field slots table<string, SlotSpawnData> Slot key to spawn configuration.
---@field tags? string[] Tags applied to all units in this layer.

return {}
