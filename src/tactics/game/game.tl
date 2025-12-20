require("src/tactics/debug")

require("src/tactics/types")
require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")

require("src/tactics/data/battles")

require("src/tactics/battle/battle_manager")
require("src/tactics/game/game_menu_manager")
require("src/tactics/systems/service")
require("src/tactics/character/character_manager")
require("src/tactics/turn_manager")
require("src/tactics/battle/tactics/enemy_ai")
require("src/tactics/story/story_context")
require("src/tactics/story/story")
require("src/tactics/story/story_page")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/game/base_game_context")
local Joypad = require("src/tactics/joypad").Joypad


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
