require("src/menu/menu_cursor")
require("src/game_context")
require("src/util/list")

global record MenuMultipleOptionDefinition
    text: string -- label
    definition: MenuStepDefinition
    must_select: boolean -- true if must be picked before using.  Default to false
end

global record MenuMultipleOptionSelection
    text: string -- label
    selection: MenuCursor
    must_select: boolean -- true if must be picked before using.  Default to false
end

global enum MultipleOptionsDirection
    "vertical"
    "horizontal"
    "select"
end

global record MultipleOptionsMenuCursor
    is MenuCursor
    where self.type == "CURSOR_MULTIPLE_OPTIONS"
    i: integer
    primary_direction: MultipleOptionsDirection
    wrap: boolean
    is_option_selected: boolean -- if the current selection has been selected.  Needed if the selection is must_select
    options: { MenuMultipleOptionSelection }
end

function MultipleOptionsMenuCursor.new(i: integer, options: {MenuStepDefinition}): MultipleOptionsMenuCursor
    local self: MultipleOptionsMenuCursor = {
        type = "CURSOR_MULTIPLE_OPTIONS",
        i = i,
        options = List.do_map(
            options,
            function(o: MenuStepDefinition): MenuCursor
                return MenuCursor.of(o)
            end
        ),
    }
    return setmetatable(self, { __index = MultipleOptionsMenuCursor })
end

function MultipleOptionsMenuCursor:update_option(joy: Joypad)
    local current_selection = self.options[self.i]
    if self.is_option_selected or not current_selection.must_select then
        current_selection.selection:update(joy)
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
        self.i = mid(1, new_i, #self.options)
    end
end