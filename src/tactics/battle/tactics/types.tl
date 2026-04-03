
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit

local record UnitDeathPayload
	attacker: BattleUnit
	defender: BattleUnit
	chapter: integer
	turn_number: integer
end

local record BattleEndPayload
	chapter: integer
	turn_number: integer
end

local payloads = {
	UnitDeathPayload = UnitDeathPayload,
	BattleEndPayload = BattleEndPayload,
}

return {
	payloads = payloads,
}
