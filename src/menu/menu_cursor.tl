require("src/menu/types")
require("src/game_context")
require("src/joypad")
require("src/systems/event_bus")

global type MenuState
global type MenuContext
global type MenuCursor

global interface MenuCursor<GC is GameContext>
    type: MenuType
    update: function(self, Joypad) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    --new: function(step_definition: MenuStepDefinition<GC, self>, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): self
    new: function(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): self
end

global interface MenuStepDefinition<GC is GameContext>
    type: MenuType
    previous_state: MenuStep
end