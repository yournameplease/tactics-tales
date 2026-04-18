---@brief
--- Defines the data structures used to hold the transient state
--- for various menu systems.

---@class TileSelection
---@field point Point
---@field path Point[] Path of points leading to the selected tile.

---@class UnitSelection
---@field point Point
---@field unit BattleUnit

---@class ItemSelection
---@field index integer
---@field item Item

---@class ScriptSelection
---@field script_id ScriptId
---@field target_unit BattleUnit
---@field target_tile Point

---@alias MenuContextId "acting_unit"|"destination"|"target_unit"|"selected_item"

---@class StorySelection
---@field id string Story ID.

---@class CharacterCustomizationSelection
---@field appearance table<string, string> Map from CharacterAppearanceKey to chosen value.

---@class GameContext Abstract base for game state passed to menu handlers.

---@class MenuContext Abstract base for menu-specific transient session state.
---@field metadata table<string, any>

---@class BattleMainMenuContext : MenuContext
---@field acting_unit UnitSelection
---@field destination TileSelection
---@field target_unit UnitSelection
---@field selected_script ScriptSelection
---@field selected_item ItemSelection
---@field metadata table<string, any>

---@class StorySelectMenuContext : MenuContext
---@field metadata table<string, any>

---@class StoryMenuContext : MenuContext
---@field metadata table<string, any>
---@field character_customization CharacterCustomizationSelection

local menu_context = {}

return menu_context
