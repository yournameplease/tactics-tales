---@brief
--- Defines event payload types for battle-level events.

---@class UnitDeathPayload
---@field attacker BattleUnit The unit that dealt the killing blow.
---@field defender BattleUnit The unit that was killed.
---@field chapter integer Story chapter number in which this death occurred.
---@field turn_number integer Battle turn on which this death occurred.
local UnitDeathPayload = {}

---@class BattleEndPayload
---@field chapter integer Story chapter number in which this battle ended.
---@field turn_number integer Battle turn on which the battle ended.
local BattleEndPayload = {}

return {
    payloads = {
        UnitDeathPayload = UnitDeathPayload,
        BattleEndPayload = BattleEndPayload,
    }
}
