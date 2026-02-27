---@brief
--- A UI panel that displays contextual control hints (e.g., "Select", "Back").

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local input_service = require("src.tactics.joypad")
local InputMethod = input_service.InputMethod
local InputLabel = input_service.InputLabel
local menu_manager = require("src.tactics.menu.menu_manager")

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

local function control_hint_row(
	input_label: InputLabel,
	menu_step_func: function(UIContextManager): menu_manager.MenuStep
): box.UIElement
	local row = box.builder("control_row_"..input_label)
		:direction("row")
		:container("strip")
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
			flex_grow = 1,
            padding = box.layout.padding(1),
		}
		:on_update(function(self: box.UIElement, state: UIContextManager)
			local menu_step = menu_step_func(state)

			if menu_step == nil or menu_step.control_hints == nil then
				self.text.content = {}
				return
			end
			
			self.text.content = { menu_step.control_hints[input_label] }
		end)
	    :build())

	return row
end

function control_hints.new(
	menu_step_func: function(UIContextManager): menu_manager.MenuStep
): box.UIElement
    local self = box.builder("control_hints")
		:direction("col")
		:container("block")
	    :build()

	self:add(control_hint_row("primary", menu_step_func))
	self:add(control_hint_row("secondary", menu_step_func))

	return self
end

return control_hints

