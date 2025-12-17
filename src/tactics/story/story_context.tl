require('src/game_context')
-- local character_manager = require('src/character/character_manager')
local StoryTypes = require('src/story/types')

global type CharacterManager
global type StoryPage
global type StoryMenuManager
global type BattleManager
global type GameServiceBundle 


global record StoryContext
    is GameContext
    where self.type == 'story'
	
    story_id: StoryTypes.StoryId

    story_page: StoryPage

    -- character_manager: character_manager.CharacterManager	
    character_manager: CharacterManager	
    menu_manager: StoryMenuManager
end

function StoryContext.new(services: GameServiceBundle): StoryContext
    return {
        type = 'story',
        services = services,
    }
end
