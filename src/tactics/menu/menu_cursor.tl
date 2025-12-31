require("src/tactics/menu/types")
local event_bus = require("src/tactics/systems/event_bus")
local Joypad = require("src/tactics/joypad").Joypad

local enum MenuType
    "CURSOR_GRID"
    "CURSOR_LIST"
    "CURSOR_BUTTON_ADVANCE"
    "CURSOR_MULTIPLE_OPTIONS"
end

local interface MenuCursor<GC>
    type: MenuType
    update: function(self, Joypad) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): string, event_bus.GameEvent
end

local interface MenuStepDefinition<GC>
    type: MenuType
    previous_state: MenuStep
    to_cursor: function(self, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
end

local menu_cursor = {
    MenuCursor = MenuCursor,
    MenuStepDefinition = MenuStepDefinition,
}

return menu_cursor
