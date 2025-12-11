require("src/battle/battle_ui_context")
require("src/battle/battle_map")
require("src/battle/tactics/battle_unit")
require("src/battle/pathfinding")
require("src/battle/tactics/tactics_engine")
require("src/battle/battle_map")
require("src/menu/menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/battle/battle_objective_service")

global record BattleContext
	
    battle_id: string
	
    battle_map: BattleMap

    tactics_engine: TacticsEngine
    battle_objective_service: BattleObjectiveService
    enemy_ai_engine: EnemyAIEngine
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager
end
