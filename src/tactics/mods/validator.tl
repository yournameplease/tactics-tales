---@brief
--- A service to validate loaded game data against the mod schemas.

local GameData = require("src.tactics.game_data").GameData

local mod_validator = {
	
}

function mod_validator.validate_game_data(game_data: GameData): boolean, {string}
	return true, {}
end

return mod_validator
