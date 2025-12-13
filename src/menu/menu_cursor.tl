require("src/menu/types")
require("src/game_context")
require("src/joypad")
require("src/systems/event_bus")

global type MenuState
global type MenuContext
global type MenuCursor

global interface MenuStepDefinition<GC is GameContext>
    type: MenuType
    previous_state: MenuStep
end

global interface MenuCursor<GC is GameContext, D is MenuStepDefinition<GC>>
    type: MenuType
    update: function(self, Joypad) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    new: function(step_definition: D, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): self
end