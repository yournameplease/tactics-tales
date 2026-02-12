---@brief
--- A UI panel that displays contextual control hints (e.g., "Select", "Back").

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local sprite_node = require("src.tactics.ui.components.sprite_node")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local input_service = require("src.tactics.joypad")
local InputMethod = input_service.InputMethod
local InputLabel = input_service.InputLabel

local record ControlHints
    is box.UIElement
end

setmetatable(ControlHints, { __index = box.Box })

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
	local row = box.flex_row()

	row:add(sprite_node.dynamic(sprite_function(input_label), {
		internal_margin = {
			t = 1,
		},
		w = 9,
		h = 9
	}))
	row:add(text_node.new({
		func = function(_self, state: UIContextManager): {string}
			return { state.input_actions[input_label] }
		end,
		flex_grow = 1,
		draw_properties = {
			wrap = "no_wrap",
		}
	}))

	return row
end

function control_hints.new(): ControlHints
    local self = box.col()

	self:add(control_hint_row("primary"))
	self:add(control_hint_row("secondary"))
	
    return self as ControlHints
end

return control_hints

