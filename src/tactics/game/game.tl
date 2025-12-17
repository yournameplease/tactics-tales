

require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_manager")
require("src/game/game_menu_manager")
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
    self.game_ctx.menu_manager:set_menu("MENU_MAIN_MENU")

    services.ui_context:register_context(self.game_ctx)

    services.event_bus:on("GAME_BEGIN_STORY", function()
        self:begin_story()
    end)
    services.event_bus:on("GAME_SET_OPTIONS", function(ctx: MenuContext)
        LOG.debug(
            "TODO: set options: ",
            ctx.metadata["log_level"],
            ctx.metadata["draw_flexbox_debug"]
            )
        self.game_ctx.menu_manager:set_menu("MENU_MAIN_MENU")
    end)

    return self
end

function Game:update(joy: Joypad)
    if self.story ~= nil then
        self.story:update(joy)
    else
        self.game_ctx.menu_manager:update(joy)
    end
end

return Game
