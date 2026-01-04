local MapDefinition = require("src/tactics/battle/map/types").MapDefinition
local BattleDefinition = require("src/tactics/battle/definition").BattleDefinition
local story = require("src/tactics/story/types")
local StoryId = story.StoryId
local StoryDefinition = story.StoryDefinition
-- local MapDefinition = require("src/tactics/battle/map/types").MapDefinition
local ItemDefinition = require("src/tactics/types/item_definition").ItemDefinition

local record GameData
	maps: { string: MapDefinition }
	battles: { string: BattleDefinition }
	stories: { StoryId: StoryDefinition }
	-- characters: { string:  }
	items: { string: ItemDefinition }
end

local game_data = {
	GameData = GameData
}

return game_data
