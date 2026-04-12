---@brief
--- Defines event payload types for battle-level events.

---@class UnitDeathPayload
---@field attacker? BattleUnit The unit that dealt the killing blow.
---@field defender BattleUnit The unit that was killed.
---@field chapter integer Story chapter number in which this death occurred.
---@field turn_number integer Battle turn on which this death occurred.

---@alias BattleEndResult
---| "VICTORY"
---| "DEFEAT"

---@class BattleEndPayload
---@field chapter integer Story chapter number in which this battle ended.
---@field turn_number integer Battle turn on which the battle ended.
---@field result BattleEndResult Whether the battle was a victory or defeat.

return {}
