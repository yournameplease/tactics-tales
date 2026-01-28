local bm = require("src/tactics/battle/battle_map")
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")

local record BattleMenuContext
    battle_map: bm.BattleMap
    tactics_engine: tactics_engine.TacticsEngine
end

local battle_menu_context = {
    BattleMenuContext = BattleMenuContext
}

function battle_menu_context.new(
    map: bm.BattleMap,
    tactics: tactics_engine.TacticsEngine
): BattleMenuContext
    return {
        battle_map = map,
        tactics_engine = tactics,
    }
end

return battle_menu_context
