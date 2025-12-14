require("src/game_context")

global type GameMenuManager

global record BaseGameContext
	is GameContext
	where self.type == "game"
	menu_manager: GameMenuManager 
end

function BaseGameContext.new(services: GameServiceBundle): BaseGameContext
	return {
		type = "game",
		services = services,
	}
end
