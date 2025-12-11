require("src/battle/battle_ui_context")
require("src/battle/battle_state")
require("src/battle/tactics/battle_unit")
require("src/battle/tile_manager")
require("src/battle/tactics/tactics_engine")
require("src/battle/map/map_manager")
require("src/menu/menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/battle/battle_objective_service")

local record BattleContext
	
    battle_id: string
	
    battle_state: BattleState
    map_data: MapData

    tile_manager: TileManager
    tactics_engine: TacticsEngine
    battle_objective_service: BattleObjectiveService
    enemy_ai_engine: EnemyAIEngine
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager
end

return {
	BattleContext = BattleContext
}
