require("src/tactics/menu/types")
require("src/tactics/game_context")
require("src/tactics/joypad")
require("src/tactics/systems/event_bus")
local Joypad = require("src/tactics/joypad").Joypad

global type MenuState
global type MenuContext
global type MenuCursor

global interface MenuCursor<GC>
    type: MenuType
    update: function(self, Joypad) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    --new: function(step_definition: MenuStepDefinition<GC, self>, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): self
    new: function(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): self
end

global interface MenuStepDefinition<GC>
    type: MenuType
    previous_state: MenuStep
    to_cursor: function(self, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
end
