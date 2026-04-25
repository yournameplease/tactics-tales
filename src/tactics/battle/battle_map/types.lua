---@brief
--- Contains miscellaneous type definitions used for battle map interactions,
--- particularly for scripting purposes.

---@alias TileDistance "on"|"adjacent" How close a unit must be to trigger an interaction.
---@alias ScriptId integer Runtime ID of an active BattleScript instance.
---@alias UnitId integer Runtime ID of an active BattleUnit instance.

---@class InteractionHook Runtime interaction with resolved tile and unit targets, used for menu navigation.
---@field script_id ScriptId ID of the BattleScript to invoke when the interaction triggers.
---@field interaction_text string Prompt text shown to the player when the interaction is available.
---@field target_tile Point Tile position associated with this interaction.
---@field target_unit BattleUnit Unit target associated with this interaction.

---@class TileInteractionHook Definition-time interaction triggered by proximity to a tile.
---@field script_id ScriptId ID of the BattleScript to invoke when the interaction triggers.
---@field interaction_text string Prompt text shown to the player when the interaction is available.
---@field interaction_distance TileDistance How close a unit must be to trigger this interaction.

---@class UnitInteractionHook Definition-time interaction triggered by proximity to a unit.
---@field script_id ScriptId ID of the BattleScript to invoke when the interaction triggers.
---@field interaction_text string Prompt text shown to the player when the interaction is available.

return {
}
