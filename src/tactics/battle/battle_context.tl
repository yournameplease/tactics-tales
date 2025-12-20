require('src/tactics/battle/battle_map')
require('src/tactics/battle/tactics/tactics_engine')

local record BattleMenuContext
    battle_map: BattleMap
    tactics_engine: TacticsEngine
end

local battle_menu_context = {
    BattleMenuContext = BattleMenuContext
}

function battle_menu_context.new(
    battle_map: BattleMap,
    tactics_engine: TacticsEngine
): BattleMenuContext
    return {
        battle_map = battle_map,
        tactics_engine = tactics_engine,
    }
end

return battle_menu_context
