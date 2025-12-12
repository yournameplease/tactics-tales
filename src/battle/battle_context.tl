require('src/game_context')

global type BattleMap 
global type TacticsEngine 
global type BattleObjectiveService 
global type EnemyAIEngine 
global type BattleMenuManager 
global type TurnManager 
global type GameServiceBundle 

global record BattleContext
    is GameContext
    where self.type == 'battle'
	
    battle_id: string
	
    battle_map: BattleMap

    tactics_engine: TacticsEngine
    battle_objective_service: BattleObjectiveService
    enemy_ai_engine: EnemyAIEngine
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager

    services: GameServiceBundle
end

function BattleContext.new(services: GameServiceBundle): BattleContext
    return {
        type = 'battle',
        services = services,
    }
end
