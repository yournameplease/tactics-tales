---@brief
--- A UI panel that displays contextual control hints (e.g., "Select", "Back").

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local input_service = require("src.tactics.joypad")
local InputMethod = input_service.InputMethod
local InputLabel = input_service.InputLabel

local control_hints = {}

local type ActionSprites = { InputLabel: integer }

local SPRITES <total>: { InputMethod: ActionSprites } = {
	mouse = {
		primary = 16,
		secondary = 17,
	},
	keyboard = {
		primary = 18,
		secondary = 19,
	},
	joypad = {
		primary = 20,
		secondary = 21,
	},
}

local function sprite_function(
	input_label: InputLabel
): function(state: UIContextManager): integer
	return function(state: UIContextManager): integer
		return SPRITES[state.game_context.input_method][input_label]
	end
end

local function control_hint_row(input_label: InputLabel): box.UIElement
	local row = box.builder("control_row_"..input_label)
	:layout(box.layout.row_fill())
	:build()

	row:add(
		box.builder("control_sprite_"..input_label)
		:sprite{
			ox = 1,
			oy = 1
		}
		:layout{
			width = 9,
			height = 9,
		}
	    :on_update(function(self: box.UIElement, state: UIContextManager)
			self.sprite.s = sprite_function(input_label)(state)
	    end)
	    :build())
	row:add(
		box.builder("control_text_"..input_label)
		:text{
			draw_properties = {
				wrap = "no_wrap"
			}
		}
		:layout{
			flex_grow = 1
		}
		:on_update(function(self: box.UIElement, state: UIContextManager)
			self.text.content = { state.input_actions[input_label] }
		end)
	    :build())

	return row
end

function control_hints.new(): box.UIElement
    return box.builder("control_hints")
    :layout(box.layout.col_fit())
    :build()
	:add(control_hint_row("primary"))
	:add(control_hint_row("secondary"))
end

return control_hints

