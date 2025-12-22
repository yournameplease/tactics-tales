require("src/tactics/debug")

require("src/tactics/types")
require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")

require("src/tactics/data/battles")

require("src/tactics/battle/battle_manager")
require("src/tactics/game/game_menu_manager")
require("src/tactics/systems/service")
require("src/tactics/turn_manager")
require("src/tactics/battle/tactics/enemy_ai")
require("src/tactics/story/story_context")
require("src/tactics/story/story")
require("src/tactics/story/story_page")
require("src/tactics/ui/ui_context_manager")
local game_menu_context = require("src/tactics/game/base_game_context")
local game_ui_context = require("src/tactics/game/game_ui_context")
local Joypad = require("src/tactics/joypad").Joypad
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle


global record Game
	menu_manager: GameMenuManager
       	
    story: Story

    services: GameServiceBundle
end

function Game:begin_story()
    self.story = Story.new("test_story", self.services)
end

function Game.new(services: GameServiceBundle): Game 

    local self: Game = setmetatable({}, { __index = Game })
    self.services = services

    local game_menu_ctx = game_menu_context.new()
	self.menu_manager = GameMenuManager.new(game_menu_ctx, self.services.event_bus)
    self.menu_manager:set_menu("MENU_MAIN_MENU")

    local game_ui_context = game_ui_context.new(self.services.event_bus, self.menu_manager)
    self.services.ui_context:register_ui_context(game_ui_context)

    self.services.event_bus:on("GAME_BEGIN_STORY", function()
        self:begin_story()
    end)
    services.event_bus:on("GAME_SET_OPTIONS", function(ctx: MenuContext)
        LOG.debug(
            "TODO: set options: ",
            ctx.metadata["log_level"],
            ctx.metadata["draw_flexbox_debug"]
            )
        self.menu_manager:set_menu("MENU_MAIN_MENU")
    end)

    return self
end

function Game:update(joy: Joypad)
    if self.story ~= nil then
        self.story:update(joy)
    else
        self.menu_manager:update(joy)
    end
end

return Game
