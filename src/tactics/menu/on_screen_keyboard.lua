---@brief
--- Implements an on-screen keyboard menu, providing character input
--- via a navigable grid of keys.

local menu_manager = require("src.tactics.menu.menu_manager")
local list = require("src.tactics.menu.cursor.nested.list")
local grid = require("src.tactics.menu.cursor.nested.grid")
local button = require("src.tactics.menu.cursor.button")
local step_definition = menu_manager.definition.step

local LAYOUT_LOWER = {
    {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p"},
    {"a", "s", "d", "f", "g", "h", "j", "k", "l", ";"},
    {"z", "x", "c", "v", "b", "n", "m", ",", ".", "/"},
    {"!", "@", "#", "$", "%", "^", "&", "*", "(", ")"},
}
local LAYOUT_UPPER = {
    {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    {"A", "S", "D", "F", "G", "H", "J", "K", "L", ":"},
    {"Z", "X", "C", "V", "B", "N", "M", "<", ">", "?"},
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
}
local LAYOUT_SYMBOL = {
    {chr(143), chr(149), chr(131), chr(144), chr(146), chr(151), chr(147), chr(135), chr(141), chr(142)},
    {chr(127), chr(145), chr(130), chr(132), chr(133), chr(134), chr(136), chr(137), chr(138), " "},
    {chr(152), chr(150), chr(129), chr(148), chr(128), chr(140), chr(139), " ", " ", " "},
    {"`", "~", "-", "_", "+", "=", " ", " ", " ", " "},
}

local KEYBOARDS = {
    ["lower"]  = LAYOUT_LOWER,
    ["upper"]  = LAYOUT_UPPER,
    ["symbol"] = LAYOUT_SYMBOL,
}

local keyboard_modes = {
    {"upper", "Upper"},
    {"lower", "Lower"},
    {"symbol", "Symbol"},
}

---@class KeyboardMenuContext : MenuContext
---@field keyboard_mode? integer 1-based index into keyboard_modes; nil means uninitialized.
---@field keyboard_content? string Text accumulated so far; nil means uninitialized.

--- Return the character at grid position p for the given keyboard context.
---@param p Point 0-indexed grid position.
---@param session_context KeyboardMenuContext
---@return string
local function get_key_at_coordinates(p, session_context)
    if session_context.keyboard_mode == nil then
        session_context.keyboard_mode = 1
    end

    local mode = keyboard_modes[session_context.keyboard_mode][1]
    local board = KEYBOARDS[mode]

    log.debug("Getting key", p)
    return board[p.y + 1][p.x + 1]
end

---@type table<string, MenuHandler>
local HANDLERS = {}

HANDLERS["change_keyboard_mode"] = function(_services, _menu_data, session_context, _value)
    ---@cast session_context KeyboardMenuContext
    if session_context.keyboard_mode == nil then
        session_context.keyboard_mode = 1
    else
        session_context.keyboard_mode = (session_context.keyboard_mode % #keyboard_modes) + 1
    end
    return menu_manager.menu_handler.then_recompute()
end

HANDLERS["type_character"] = function(_services, _menu_data, session_context, value)
    ---@cast session_context KeyboardMenuContext
    if session_context.keyboard_mode == nil then
        session_context.keyboard_mode = 1
    end
    if session_context.keyboard_content == nil then
        session_context.keyboard_content = ""
    end

    local char
    if type(value) == "string" then
        char = value
    else
        ---@cast value NestedGridValue
        char = get_key_at_coordinates(value.point, session_context)
    end
    session_context.keyboard_content = session_context.keyboard_content .. char

    return nil
end

HANDLERS["type_text"] = function(_services, _menu_data, _session_context)
    return nil
end

HANDLERS["delete_character"] = function(_services, _menu_data, session_context, _value)
    ---@cast session_context KeyboardMenuContext
    if session_context.keyboard_mode == nil then
        session_context.keyboard_mode = 1
    end
    if session_context.keyboard_content == nil then
        session_context.keyboard_content = ""
    end

    if #session_context.keyboard_content > 0 then
        session_context.keyboard_content = string.sub(session_context.keyboard_content, 1, #session_context.keyboard_content - 1)
    end

    return nil
end

local menu_keyboard = {
    KeyboardMenuContext = {},  -- type alias placeholder
    handlers = HANDLERS,
}

--- Build a MenuStepDefinition for the on-screen keyboard.
---@param submit string MenuHandlerId to invoke when the user confirms input.
---@return MenuStepDefinition
function menu_keyboard.step(submit)
    return step_definition.of_node(
        list.column(
            "keyboard_menu",
            function(_msb, _ctx)
                local children = {}

                table.insert(children, grid.grid("keyboard", 10, 4)
                    :with_common_child(
                        button.builder("keyboard_key")
                            :with_text("key")
                            :handle_action("select", "type_character")
                            :handle_keyboard("type_character")
                    )
                    :with_text_function(function(pt_arg, _services, ctx)
                        ---@cast ctx KeyboardMenuContext
                        return get_key_at_coordinates(pt_arg, ctx)
                    end))

                table.insert(children, list.row(
                    "keyboard_navigation",
                    function(_msb2, _ctx2)
                        local options = {}
                        table.insert(options, button.builder("mode")
                            :with_text("Mode")
                            :handle_action("select", "change_keyboard_mode"))
                        table.insert(options, button.builder("random")
                            :with_text("Back")
                            :handle_action("select", "delete_character"))
                        table.insert(options, button.builder("confirm")
                            :with_text("Confirm")
                            :handle_action("select", submit))
                        return options
                    end))

                return children
            end
        )
    )
    :with_keyboard_handler("type_text")
    :with_backspace_handler("delete_character")
    :with_action("BUTTON_A", { command = "select", description = "Select" })
    :with_action("BUTTON_B", { command = "back",   description = "Back" })
end

return menu_keyboard
