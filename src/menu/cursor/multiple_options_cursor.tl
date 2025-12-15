require("src/menu/menu_cursor")
require("src/game_context")
local List = require("src/util/list")

global type MenuState

global record MenuMultipleOptionCursor<GC is GameContext>
    text: string -- label
    cursor: MenuCursor<GC>
    must_select: boolean -- true if must be picked before using.  Default to false
end

global record MenuMultipleOptionDefinition<GC>
    text: string -- label
    definition: MenuStepDefinition<GC>
    must_select: boolean -- true if must be picked before using.  Default to false
end

function MenuMultipleOptionDefinition.new(props: MenuMultipleOptionDefinition<GC>): MenuMultipleOptionDefinition<GC>
    return props
end

global enum MultipleOptionsDirection
    "vertical"
    "horizontal"
    "select"
end

global record MultipleOptionsMenuCursor<GC is GameContext>
    is MenuCursor<GC>
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
        cursor = self.definition:to_cursor(game_context, menu_ctx, menu_state),
        must_select = self.must_select,
    }
end

global record MultipleOptionsMenuDefinition<GC is GameContext>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_MULTIPLE_OPTIONS"
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    options: { MenuMultipleOptionDefinition<GC> }
    next_state: string
    send_command: GameEvent
end

function MultipleOptionsMenuDefinition.new(props: MultipleOptionsMenuDefinition<GC>): MultipleOptionsMenuDefinition<GC>
    props.type = "CURSOR_MULTIPLE_OPTIONS"
    return setmetatable(props, { __index = MultipleOptionsMenuDefinition })
end

function MultipleOptionsMenuCursor.new(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): MultipleOptionsMenuCursor<GC>
    assert(step_definition is MultipleOptionsMenuDefinition<GC>)
    local self: MultipleOptionsMenuCursor<GC> = {
        type = "CURSOR_MULTIPLE_OPTIONS",
        i = 1,
        options = List.do_map(
            step_definition.options,
            function(o: MenuMultipleOptionDefinition<GC>): MenuMultipleOptionCursor<GC>
                return {
                    text = o.text,
                    cursor = o.definition:to_cursor(game_ctx, menu_ctx, menu_state),
                    must_select = o.must_select == true
                }
            end
        ),
    }
    return setmetatable(self, { __index = function(t: any, k: string): any 
            if (MultipleOptionsMenuCursor as {string: any})[k] then
                return (MultipleOptionsMenuCursor as {string: any})[k]
            end
            return (step_definition as {string: any})[k]
        end
        })
end

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
        -- handled by handle_menu_select
    end
    
    if self.wrap then
        self.i = new_i % #self.options + 1
    else
        self.i = pt.mid(1, new_i, #self.options)
    end
end

function MultipleOptionsMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    for _, opt in ipairs(self.options) do
        opt.cursor:handle_select(game_ctx, menu_ctx, menu_state)
    end

    return self.next_state, self.send_command
end

function MultipleOptionsMenuDefinition:to_cursor(game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
    return MultipleOptionsMenuCursor.new(self, game_context, menu_ctx, menu_state)
end

