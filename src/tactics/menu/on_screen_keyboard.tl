-- local grid_cursor = require("src.tactics.menu.cursor.grid_cursor")
-- local menu_manager = require("src.tactics.menu.menu_manager")
-- local menu_context = require("src.tactics.menu.menu_context")
-- local MenuContext = menu_context.MenuContext

-- local LAYOUT_LOWER: {{string}} = {
-- 	{"q", "w", "e", "r", "t", "y", "u", "i", "o", "p",},
-- 	{"a", "s", "d", "f", "g", "h", "j", "k", "l", ";",},
-- 	{"z", "x", "c", "v", "b", "n", "m", ",", ".", "/",},
-- 	{"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",},
-- }
-- local LAYOUT_UPPER: {{string}} = {
-- 	{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",},
-- 	{"A", "S", "D", "F", "G", "H", "J", "K", "L", ":",},
-- 	{"Z", "X", "C", "V", "B", "N", "M", "<", ">", "?",},
-- 	{"!", "@", "#", "$", "%", "^", "&", "*", "(", ")",},
-- }

-- local LAYOUT_SYMBOL: {{string}} = {
-- 	{pt.chr(143), pt.chr(149), pt.chr(131), pt.chr(144), pt.chr(146), pt.chr(151), pt.chr(147), pt.chr(135), pt.chr(141), pt.chr(142),},
-- 	{pt.chr(127), pt.chr(145), pt.chr(130), pt.chr(132), pt.chr(133), pt.chr(134), pt.chr(136), pt.chr(137), pt.chr(138), " ",},
-- 	{pt.chr(152), pt.chr(150), pt.chr(129), pt.chr(148), pt.chr(128), pt.chr(140), pt.chr(139), " ", " ", " ",},
-- 	{"`", "~", "-", "_", "+", "=", " ", " ", " ", " ",},
-- } 

-- local KEYBOARDS = {
-- 	["lower"] = LAYOUT_LOWER,
-- 	["upper"] = LAYOUT_upper,
-- 	["symbol"] = LAYOUT_symbol,
-- }


-- local HANDLERS: { menu_types.MenuHandlerId: menu_manager.MenuHandler } = {}

-- HANDLERS["change_keyboard_mode"] = function(
--     _services: BattleMenuContext,
--     _menu_data: {string: any},
--     session_context: MenuContext,
--     value: grid.NestedGridValue
-- )
--     session_context.keyboard = services.battle_map:get_at_tile(value.point)
-- end

-- local menu_keyboard = {}

-- function menu_keyboard.step(submit: string): menu_manager.MenuStepDefinition
-- 	return step_definition.of_node(
--         list.column(
--             "options_menu",
--             function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
--                 local children: {MenuNodeDefinition} = {}

--                 pt.add(children, list.grid("keyboard")
-- 					:with_common_child(
-- 						button.builder("keyboard_key")
-- 	                        :with_text("key")
-- 	                        :handle_select("type_character")	
-- 				))
                    
--                 pt.add(children, list.row(
--                     "options_navigation",
--                     function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
--                         local options: {MenuNodeDefinition} = {}
--                         pt.add(options, button.builder("reset")
--                             :with_text("Mode")
--                             :handle_select("change_keyboard_mode"))
--                         pt.add(options, button.builder("reset")
--                             :with_text("Random")
--                             :handle_select("reset_options")
--                             :advance_to("MAIN_MENU"))
--                         pt.add(options, button.builder("save")
--                             :with_text("Confirm")
--                             :handle_select("set_options")
--                             :advance_to("MAIN_MENU"))
--                         return options
--                     end))

--                 return children
--             end
--         )
-- 	)
-- end

-- local MENU_DATA: menu_manager.MenuDefinition = {
-- 	steps = {
-- 	    ["KEYBOARD_LOWER"] = grid_cursor.definition({
-- 			select_handler = function(_self: grid_cursor.GridMenuNode, game_ctx: MenuContext, menu_ctx: MenuContext)
-- 	                end
-- 		}),
-- 	    ["KEYBOARD_UPPER"] = grid_cursor.definition({
		
-- 		}),
-- 	    ["KEYBOARD_SYMBOL"] = grid_cursor.definition({
		
-- 		}),
-- 	},
-- }

-- return on_screen_keyboard
