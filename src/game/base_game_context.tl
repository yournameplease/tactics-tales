require("src/game_context")

global type GameMenuManager

global record BaseGameContext
	is GameContext
	menu_manager: GameMenuManager 
end

function BaseGameContext.new(services: GameServiceBundle): BaseGameContext
	return {
		services = services
	}
end
