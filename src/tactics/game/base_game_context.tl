require("src/tactics/game_context")

local record GameMenuContext
end

local game_menu_context = {
	GameMenuContext = GameMenuContext
}

function game_menu_context.new(): GameMenuContext
	return {}
end

return game_menu_context
