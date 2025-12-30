local menu_cursor = require("src/tactics/menu/menu_cursor")
require("src/tactics/menu/types")
local lists = require("src/tactics/util/lists")
local Joypad = require("src/tactics/joypad").Joypad

local record MenuMultipleOptionCursor<GC>
    text: string -- label
    key: string --ugh.  here for ui context
    cursor: menu_cursor.MenuCursor<GC>
    must_select: boolean -- true if must be picked before using.  Default to false
end

local record MenuMultipleOptionDefinition<GC>
    text: string -- label
    key: string --ugh.  here for ui context
    definition: menu_cursor.MenuStepDefinition<GC>
    must_select: boolean -- true if must be picked before using.  Default to false
end

global enum MultipleOptionsDirection
    "vertical"
    "horizontal"
    "none"
end

local record MultipleOptionsMenuCursor<GC>
    is menu_cursor.MenuCursor<GC>
    where self.type == "CURSOR_MULTIPLE_OPTIONS"
    i: integer
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    is_option_selected: boolean -- if the current selection has been selected.  Needed if the selection is must_select
    options: { MenuMultipleOptionCursor<GC> }
    next_state: string
    send_command: GameEvent
end

function MenuMultipleOptionDefinition:to_cursor(game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuMultipleOptionCursor<GC>
    return {
        text = self.text,
        key = self.key,
        cursor = self.definition:to_cursor(game_context, menu_ctx, menu_state),
        must_select = self.must_select,
    }
end

local record MultipleOptionsMenuDefinition<GC>
    is menu_cursor.MenuStepDefinition<GC>
    where self.type == "CURSOR_MULTIPLE_OPTIONS"
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    options: { MenuMultipleOptionDefinition<GC> }
    next_state: string
    send_command: GameEvent
end

local multiple_options_cursor = {
    MenuMultipleOptionCursor = MenuMultipleOptionCursor,    
    MenuMultipleOptionDefinition = MenuMultipleOptionDefinition,    
    MultipleOptionsMenuCursor = MultipleOptionsMenuCursor,
    MultipleOptionsMenuDefinition = MultipleOptionsMenuDefinition,
}

function multiple_options_cursor.option_definition<GC>(props: MenuMultipleOptionDefinition<GC>): MenuMultipleOptionDefinition<GC>
    return props
end

function multiple_options_cursor.definition<GC>(props: MultipleOptionsMenuDefinition<GC>): MultipleOptionsMenuDefinition<GC>
    props.type = "CURSOR_MULTIPLE_OPTIONS"
    return setmetatable(props, { __index = MultipleOptionsMenuDefinition })
end

-- function MultipleOptionsMenuCursor.new(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): MultipleOptionsMenuCursor<GC>
--     assert(step_definition is MultipleOptionsMenuDefinition<GC>)
--     local self: MultipleOptionsMenuCursor<GC> = {
--         type = "CURSOR_MULTIPLE_OPTIONS",
--         i = 1,
--         options = lists.do_map(
--             step_definition.options,
--             function(o: MenuMultipleOptionDefinition<GC>): MenuMultipleOptionCursor<GC>
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

function MultipleOptionsMenuCursor:update_option(joy: Joypad)
    local current_selection = self.options[self.i]
    if self.is_option_selected or not current_selection.must_select then
        current_selection.cursor:update(joy)
    end
end

function MultipleOptionsMenuCursor:update(joy: Joypad)
    local new_i = self.i
    if self.primary_direction == "vertical" then
        if joy.dyp ~= 0 then
            new_i = new_i + joy.dyp
        else
            self:update_option(joy)
        end
    elseif self.primary_direction == "horizontal" then
        if joy.dxp ~= 0 then
            new_i = new_i + joy.dxp
        else
            self:update_option(joy)
        end
    elseif self.primary_direction == "select" then
        -- movement handled by handle_menu_select
        if joy.dxp ~= 0 or joy.dyp ~= 0 then
            self:update_option(joy)
        end
    end
    
    if self.wrap then
        self.i = new_i % #self.options + 1
    else
        self.i = pt.mid(1, new_i, #self.options)
    end
end

function MultipleOptionsMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    if self.primary_direction == "select" and self.i ~= #self.options then
        self.i = self.i + 1
        return nil, nil
    else
        for _, opt in ipairs(self.options) do
            opt.cursor:handle_select(game_ctx, menu_ctx, menu_state)
        end
        return self.next_state, self.send_command
    end
end

function MultipleOptionsMenuDefinition:to_cursor(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): menu_cursor.MenuCursor<GC>
    local cursor: MultipleOptionsMenuCursor<GC> = {
        type = "CURSOR_MULTIPLE_OPTIONS",
        i = 1,
        options = lists.do_map(
            self.options,
            function(o: MenuMultipleOptionDefinition<GC>): MenuMultipleOptionCursor<GC>
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
