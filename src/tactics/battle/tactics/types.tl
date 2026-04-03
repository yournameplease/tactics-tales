
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit

local record UnitDeathPayload
	attacker: BattleUnit
	defender: BattleUnit
	chapter: integer
	turn_number: integer
end

local payloads = {
	UnitDeathPayload = UnitDeathPayload,
}

return {
	payloads = payloads,
}
