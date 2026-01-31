local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_types = require("src.tactics.menu.types")
local MenuContext = require("src.tactics.menu.menu_context").MenuContext
local lists = require("src.tactics.util.lists")
local event_bus = require("src.tactics.systems.event_bus")
local input_service = require("src.tactics.joypad")
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local record MenuMultipleOptionCursor<GameContext>
    text: string -- label
    key: string --ugh.  here for ui context
    cursor: menu_cursor.MenuCursor<GameContext>
    must_select: boolean -- true if must be picked before using.  Default to false
end

local record MenuMultipleOptionDefinition<GameContext>
    text: string -- label
    key: string --ugh.  here for ui context
    definition: menu_cursor.MenuStepDefinition<GameContext>
    must_select: boolean -- true if must be picked before using.  Default to false
    back_command: event_bus.GameEvent
end

global enum MultipleOptionsDirection
    "vertical"
    "horizontal"
    "select"
end

local record MultipleOptionsMenuCursor<GameContext>
    is menu_cursor.MenuCursor<GameContext>
    where self.type == "multiple_options"
    i: integer
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    is_option_selected: boolean -- if the current selection has been selected.  Needed if the selection is must_select
    options: { MenuMultipleOptionCursor<GameContext> }
    next_state: string
    select_handler: function(self, GameContext, MenuContext)
    back_handler: function(self, GameContext, MenuContext)
end

function MenuMultipleOptionDefinition:to_cursor(game_context: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): MenuMultipleOptionCursor<GameContext>
    return {
        text = self.text,
        key = self.key,
        cursor = self.definition:to_cursor(game_context, menu_ctx, menu_state),
        must_select = self.must_select,
    }
end

local record MultipleOptionsMenuDefinition<GameContext>
    is menu_cursor.MenuStepDefinition<GameContext>
    where self.type == "multiple_options"
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    options: { MenuMultipleOptionDefinition<GameContext> }
    next_state: string
    select_handler: function(self, GameContext, MenuContext)
    back_handler: function(self, GameContext, MenuContext)
end

local multiple_options_cursor = {
    MenuMultipleOptionCursor = MenuMultipleOptionCursor,    
    MenuMultipleOptionDefinition = MenuMultipleOptionDefinition,    
    MultipleOptionsMenuCursor = MultipleOptionsMenuCursor,
    MultipleOptionsMenuDefinition = MultipleOptionsMenuDefinition,
}

function multiple_options_cursor.option_definition<GameContext>(props: MenuMultipleOptionDefinition<GameContext>): MenuMultipleOptionDefinition<GameContext>
    return props
end

function multiple_options_cursor.definition<GameContext>(props: MultipleOptionsMenuDefinition<GameContext>): MultipleOptionsMenuDefinition<GameContext>
    props.type = "multiple_options"
    return setmetatable(props, { __index = MultipleOptionsMenuDefinition })
end

-- function MultipleOptionsMenuCursor.new(step_definition: any, game_ctx: GameContext, menu_ctx: MenuContext, menu_state: MenuState): MultipleOptionsMenuCursor<GameContext>
--     assert(step_definition is MultipleOptionsMenuDefinition<GameContext>)
--     local self: MultipleOptionsMenuCursor<GameContext> = {
--         type = "CURSOR_MULTIPLE_OPTIONS",
--         i = 1,
--         options = lists.do_map(
--             step_definition.options,
--             function(o: MenuMultipleOptionDefinition<GameContext>): MenuMultipleOptionCursor<GameContext>
--                 return {
--                     text = o.text,
--                     key = o.key,
--                     cursor = o.definition:to_cursor(game_ctx, menu_ctx, menu_state),
--                     must_select = o.must_select == true
--                 }
--             end
--         ),
--     }
--     return setmetatable(self, { __index = function(t: any, k: string): any 
--             if (MultipleOptionsMenuCursor as {string: any})[k] then
--                 return (MultipleOptionsMenuCursor as {string: any})[k]
--             end
--             return (step_definition as {string: any})[k]
--         end
--         })
-- end

function MultipleOptionsMenuCursor:update_option_joy(joy: Joypad)
    local current_selection = self.options[self.i]
    if self.is_option_selected or not current_selection.must_select then
        current_selection.cursor:update_joy(joy)
    end
end

function MultipleOptionsMenuCursor:update_option_mouse(
    mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection
)
    local current_selection = self.options[self.i]
    if self.is_option_selected or not current_selection.must_select then
        current_selection.cursor:update_mouse(mouse, hovered)
    end
end

function MultipleOptionsMenuCursor:update_joy(joy: Joypad)
    local new_i = self.i
    if self.primary_direction == "vertical" then
        if joy.dyp ~= 0 then
            new_i = new_i + joy.dyp
        else
            self:update_option_joy(joy)
        end
    elseif self.primary_direction == "horizontal" then
        if joy.dxp ~= 0 then
            new_i = new_i + joy.dxp
        else
            self:update_option_joy(joy)
        end
    elseif self.primary_direction == "select" then
        -- movement handled by handle_menu_select
        if joy.dxp ~= 0 or joy.dyp ~= 0 then
            self:update_option_joy(joy)
        end
    end
    
    if self.wrap then
        self.i = new_i % #self.options + 1
    else
        self.i = pt.mid(1, new_i, #self.options)
    end
end

function MultipleOptionsMenuCursor:update_mouse(
    mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection
)
end

function MultipleOptionsMenuCursor:handle_select(game_ctx: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): string 
    if self.primary_direction == "select" and self.i ~= #self.options then
        self.i = self.i + 1
        return nil 
    else
        for _, opt in ipairs(self.options) do
            opt.cursor:handle_select(game_ctx, menu_ctx, menu_state)
        end
        if self.select_handler then
            self:select_handler(game_ctx, menu_ctx)
        end
        return self.next_state 
    end
end

function MultipleOptionsMenuCursor:handle_back(
    game_ctx: GameContext,
    menu_ctx: MenuContext
)
    if self.back_handler then
        self:back_handler(game_ctx, menu_ctx)
    end
end

function MultipleOptionsMenuDefinition:to_cursor(game_ctx: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): menu_cursor.MenuCursor<GameContext>
    local cursor: MultipleOptionsMenuCursor<GameContext> = {
        type = "multiple_options",
        i = 1,
        options = lists.do_map(
            self.options,
            function(o: MenuMultipleOptionDefinition<GameContext>): MenuMultipleOptionCursor<GameContext>
                return {
                    text = o.text,
                    key = o.key,
                    cursor = o.definition:to_cursor(game_ctx, menu_ctx, menu_state),
                    must_select = o.must_select == true
                }
            end
        ),
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (MultipleOptionsMenuCursor as {string: any})[k] then
                return (MultipleOptionsMenuCursor as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

return multiple_options_cursor
