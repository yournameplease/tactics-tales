

require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_manager")
require("src/menu/menu_manager")
require("src/menu/game_menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/story/story_context")
require("src/story/story")
require("src/story/story_page")
require("src/ui/ui_context_manager")
require("src/game/base_game_context")


global record Game

	game_ctx: BaseGameContext
   	
    story: Story

end

function Game:begin_story()
    self.story = Story.new("test_story", self.game_ctx.services)
end

function Game.new(services: GameServiceBundle): Game 

    local self: Game = setmetatable({}, { __index = Game })
    self.game_ctx = BaseGameContext.new(services)

	self.game_ctx.menu_manager = GameMenuManager.new(self.game_ctx)

    services.ui_context:register_context(self.game_ctx)

    services.event_bus:on("BATTLE_END_DEFEAT", function()
        self:begin_story()
    end)

    return self
end

function Game:update(joy: Joypad)
    self.game_ctx.menu_manager:update(joy)
end

return Game
