local point = require("src.tactics.util.point")
local Point = point.Point
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit

-- used by interaction scripts
local enum TileDistance
	"on"
	"adjacent"
end

local record InteractionHook
    script_id: integer 
    interaction_text: string
	target_tile: Point
	target_unit: BattleUnit
end

local record TileInteractionHook
    script_id: integer 
    interaction_text: string
    interaction_distance: TileDistance
end

local record UnitInteractionHook
    script_id: integer 
    interaction_text: string
end

return {
	TileDistance = TileDistance,
	TileInteractionHook = TileInteractionHook,
	UnitInteractionHook = UnitInteractionHook,
	InteractionHook = InteractionHook,
}


