require("src/tactics/menu/types")
require("src/tactics/systems/event_bus")
local Joypad = require("src/tactics/joypad").Joypad

global interface MenuCursor<GC>
    type: MenuType
    update: function(self, Joypad) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
end

global interface MenuStepDefinition<GC>
    type: MenuType
    previous_state: MenuStep
    to_cursor: function(self, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
end
