local MapDefinition = require("src/tactics/battle/map/types").MapDefinition
local BattleDefinition = require("src/tactics/battle/definition").BattleDefinition
local story = require("src/tactics/story/types")
local StoryId = story.StoryId
local StoryDefinition = story.StoryDefinition
local CharacterTemplate = require("src/tactics/character/definition").CharacterTemplate
local ItemDefinition = require("src/tactics/types/item_definition").ItemDefinition

local record StoryData
	data: { StoryId: StoryDefinition }
	default_story: StoryId
	story_select: { StoryId } 
end

local record GameData
	maps: { string: MapDefinition }
	battles: { string: BattleDefinition }
	stories: StoryData
	characters: { string: CharacterTemplate }
	items: { string: ItemDefinition }
end

local game_data = {
	GameData = GameData
}

return game_data
