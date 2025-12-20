require('src/tactics/game_context')

require('src/tactics/battle/battle_map')
require('src/tactics/battle/tactics/tactics_engine')

global record BattleMenuContext
    battle_map: BattleMap
    tactics_engine: TacticsEngine
end

function BattleMenuContext.new(
    battle_map: BattleMap,
    tactics_engine: TacticsEngine
): BattleMenuContext
    return {
        battle_map = battle_map,
        tactics_engine = tactics_engine,
    }
end
