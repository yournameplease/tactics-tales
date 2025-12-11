global type BattleMap 
global type TacticsEngine 
global type BattleObjectiveService 
global type EnemyAIEngine 
global type BattleMenuManager 
global type TurnManager 
global type GameServiceBundle 





global record BattleContext
	
    battle_id: string
	
    battle_map: BattleMap

    tactics_engine: TacticsEngine
    battle_objective_service: BattleObjectiveService
    enemy_ai_engine: EnemyAIEngine
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager

    services: GameServiceBundle
end
