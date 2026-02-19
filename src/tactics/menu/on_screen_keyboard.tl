local menu_manager = require("src.tactics.menu.menu_manager")
local list = require("src.tactics.menu.cursor.nested.list")
local grid = require("src.tactics.menu.cursor.nested.grid")
local button = require("src.tactics.menu.cursor.button")
local step_definition = menu_manager.definition.step
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local menu_types = require("src.tactics.menu.types")
local Point = require("src.tactics.util.point").Point

local LAYOUT_LOWER: {{string}} = {
	{"q", "w", "e", "r", "t", "y", "u", "i", "o", "p",},
	{"a", "s", "d", "f", "g", "h", "j", "k", "l", ";",},
	{"z", "x", "c", "v", "b", "n", "m", ",", ".", "/",},
	{"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",},
}
local LAYOUT_UPPER: {{string}} = {
	{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",},
	{"A", "S", "D", "F", "G", "H", "J", "K", "L", ":",},
	{"Z", "X", "C", "V", "B", "N", "M", "<", ">", "?",},
	{"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",},
}

local LAYOUT_SYMBOL: {{string}} = {
	{pt.chr(143), pt.chr(149), pt.chr(131), pt.chr(144), pt.chr(146), pt.chr(151), pt.chr(147), pt.chr(135), pt.chr(141), pt.chr(142),},
	{pt.chr(127), pt.chr(145), pt.chr(130), pt.chr(132), pt.chr(133), pt.chr(134), pt.chr(136), pt.chr(137), pt.chr(138), " ",},
	{pt.chr(152), pt.chr(150), pt.chr(129), pt.chr(148), pt.chr(128), pt.chr(140), pt.chr(139), " ", " ", " ",},
	{"`", "~", "-", "_", "+", "=", " ", " ", " ", " ",},
} 

local KEYBOARDS: {string: {{string}}} = {
	["lower"] = LAYOUT_LOWER,
	["upper"] = LAYOUT_UPPER,
	["symbol"] = LAYOUT_SYMBOL,
}

local keyboard_modes = {
	{"upper", "Upper"},
	{"lower", "Lower"},
	{"symbol", "Symbol"},
}

local record KeyboardMenuContext
	is MenuContext
    keyboard_mode: integer
    keyboard_content: string
end

local function get_key_at_coordinates(
	p: Point,
    session_context: KeyboardMenuContext
): string
	if session_context.keyboard_mode == nil then
		session_context.keyboard_mode = 1
	end

	local mode: string = keyboard_modes[session_context.keyboard_mode][1]

	local board = KEYBOARDS[mode]

	log.debug("Getting key", p)
	local key = board[p.y+1][p.x+1] 

	return key
end

local HANDLERS: { menu_types.MenuHandlerId: menu_manager.MenuHandler } = {}

HANDLERS["change_keyboard_mode"] = function(
    _services: GameContext,
    _menu_data: {string: any},
    session_context: KeyboardMenuContext,
    _value: any
): menu_manager.menu_handler.MenuHandlerPostHandling
	if session_context.keyboard_mode == nil then
		session_context.keyboard_mode = 1
	else
		session_context.keyboard_mode = (session_context.keyboard_mode % #keyboard_modes) + 1
	end

	return menu_manager.menu_handler.then_recompute()
end

HANDLERS["type_character"] = function(
    _services: GameContext,
    _menu_data: {string: any},
    session_context: KeyboardMenuContext,
    value: grid.NestedGridValue
): menu_manager.menu_handler.MenuHandlerPostHandling
	if session_context.keyboard_mode == nil then
		session_context.keyboard_mode = 1
	end
	if session_context.keyboard_content == nil then
		session_context.keyboard_content = ""
	end

	local char = get_key_at_coordinates(value.point, session_context)
	session_context.keyboard_content = session_context.keyboard_content..char

	return nil
end

HANDLERS["delete_character"] = function(
    _services: GameContext,
    _menu_data: {string: any},
    session_context: KeyboardMenuContext,
    _value: any
): menu_manager.menu_handler.MenuHandlerPostHandling
	if session_context.keyboard_mode == nil then
		session_context.keyboard_mode = 1
	end
	if session_context.keyboard_content == nil then
		session_context.keyboard_content = ""
	end

	if #session_context.keyboard_content > 0 then
		session_context.keyboard_content = pt.sub(session_context.keyboard_content, 1, #session_context.keyboard_content - 1)
	end

	return nil
end

local menu_keyboard = {
	KeyboardMenuContext = KeyboardMenuContext,
	handlers = HANDLERS,
}

function menu_keyboard.step(submit: string): menu_manager.MenuStepDefinition
	return step_definition.of_node(
        list.column(
            "keyboard_menu",
            function(_msb: GameContext, _ctx: MenuContext): {MenuNodeDefinition}
                local children: {MenuNodeDefinition} = {}

                pt.add(children, grid.grid("keyboard", 10, 4)
					:with_common_child(
						button.builder("keyboard_key")
	                        :with_text("key")
	                        :handle_select("type_character")
				):with_text_function(function(point: Point, _services: GameContext, ctx: KeyboardMenuContext): string
					return get_key_at_coordinates(point, ctx)
				end))
                    
                pt.add(children, list.row(
                    "keyboard_navigation",
                    function(_msb: GameContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}
                        pt.add(options, button.builder("mode")
                            :with_text("Mode")
                            :handle_select("change_keyboard_mode"))
                        pt.add(options, button.builder("random")
                            :with_text("Back")
                            :handle_select("delete_character"))
                        pt.add(options, button.builder("confirm")
                            :with_text("Confirm")
                            :handle_select(submit))
                        return options
                    end))

                return children
            end
        )
	)
end

return menu_keyboard
