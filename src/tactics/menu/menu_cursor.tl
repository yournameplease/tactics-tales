local menu_types = require("src/tactics/menu/types")
local MenuContext = require ("src/tactics/menu/menu_context").MenuContext
local event_bus = require("src/tactics/systems/event_bus")
local Joypad = require("src/tactics/joypad").Joypad

local enum CursorType
    "grid"
    "list"
    "button_advance"
    "multiple_options"
end

local interface MenuCursor<GC>
    type: CursorType
    update: function(self, Joypad) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: menu_types.MenuState): string, event_bus.GameEvent
end

local interface MenuStepDefinition<GC>
    type: CursorType
    previous_state: menu_types.MenuStep
    to_cursor: function(self, game_ctx: GC, menu_ctx: MenuContext, menu_state: menu_types.MenuState): MenuCursor<GC>
end

local menu_cursor = {
    CursorType = CursorType,
    MenuCursor = MenuCursor,
    MenuStepDefinition = MenuStepDefinition,
}

return menu_cursor
