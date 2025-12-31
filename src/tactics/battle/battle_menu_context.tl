local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")

local record BattleMenuContext
    battle_map: BattleMap
    tactics_engine: tactics_engine.TacticsEngine
end

local battle_menu_context = {
    BattleMenuContext = BattleMenuContext
}

function battle_menu_context.new(
    map: BattleMap,
    tactics: tactics_engine.TacticsEngine
): BattleMenuContext
    return {
        battle_map = map,
        tactics_engine = tactics,
    }
end

return battle_menu_context
