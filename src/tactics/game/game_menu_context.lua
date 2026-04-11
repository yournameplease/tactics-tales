---@brief
--- Defines the context object for the main game menu system.

local save_system = require("src.tactics.save.save_system")

---@class GameMenuContext : GameContext
---@field story_ids StoryId[] Available story IDs to present in the menu.
---@field handle_begin_story fun(save_id: string?, story_id: StoryId?) Callback to start a new story.
---@field handle_load_story fun(save_id: string) Callback to load an existing story save.
---@field get_game_saves fun(): string[] Returns list of existing save IDs.
---@field config_manager ConfigManager
local GameMenuContext = {}
GameMenuContext.__index = GameMenuContext

local game_menu_context = {
	GameMenuContext = GameMenuContext,
}

--- Create a new GameMenuContext with the given story list and handlers.
---@param story_ids StoryId[]
---@param handle_begin_story fun(save_id: string, story_id: StoryId)
---@param handle_load_story fun(save_id: string)
---@param config_manager ConfigManager
---@return GameMenuContext
function game_menu_context.new(story_ids, handle_begin_story, handle_load_story, config_manager)
	---@type GameMenuContext
	local self = setmetatable({}, GameMenuContext)
	self.story_ids = story_ids
	self.config_manager = config_manager
	self.get_game_saves = save_system.list_saves
	self.handle_begin_story = handle_begin_story
	self.handle_load_story = handle_load_story
	return self
end

return game_menu_context
