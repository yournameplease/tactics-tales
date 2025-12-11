
require('src/game_context')

global type StoryPage
global type StoryMenuManager
global type CharacterManager
global type BattleManager


global record StoryContext
    is GameContext
    where type == 'story'
	
    story_id: string

    story_page: StoryPage

    character_manager: CharacterManager	
    menu_manager: StoryMenuManager
    battle_manager: BattleManager
end

function StoryContext.new(services: GameServiceBundle): StoryContext
    return {
        type = 'battle',
        services = services,
    }
end
