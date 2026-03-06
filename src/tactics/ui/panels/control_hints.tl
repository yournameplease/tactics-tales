---@brief
--- A UI panel that displays contextual control hints (e.g., "Select", "Back").

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local input_service = require("src.tactics.joypad")
local InputLabel = input_service.InputLabel
local menu_types = require("src.tactics.menu.types")
local menu_manager = require("src.tactics.menu.menu_manager")
local text = require("src.tactics.util.text")

local control_hints = {}

local type ActionSprites = { InputLabel: integer }

local SPRITE_OFFSETS: ActionSprites = {
	primary = 0,
	secondary = 1,
}

local BASE_MOUSE_SPRITE = 16

local BASE_JOYPAD_SPRITES <total>: { GlyphFamily: integer } = {
	["keyboard"] = 24,
	["picotron"] = 32,
	["snes"] = 40,
	["nintendo"] = 48,
	["xbox"] = 56,
	["playstation"] = 64,
}


local function sprite_by_label_and_method(
	input_label: InputLabel,
	input_method: input_service.InputMethod
): integer
	local base_sprite: integer
	if input_method == "mouse" then
		base_sprite = BASE_MOUSE_SPRITE
	else
		base_sprite = BASE_JOYPAD_SPRITES[DYNAMIC_CONFIG.glyph_family]
	end
	
	return base_sprite + SPRITE_OFFSETS[input_label]
end

local function sprite_function(
	input_label: InputLabel
): function(state: UIContextManager): integer
	return function(state: UIContextManager): integer
		local base_sprite: integer
		if state.game_context.input_method == "mouse" then
			base_sprite = BASE_MOUSE_SPRITE
		else
			base_sprite = BASE_JOYPAD_SPRITES[DYNAMIC_CONFIG.glyph_family]
		end
		
		return base_sprite + SPRITE_OFFSETS[input_label]
	end
end

local function control_hint_glyphs(
	input_label: InputLabel,
	text_color: box.UITextColor
): box.UIElement
	local row = box.builder("control_row_"..input_label)
		:direction("row")
		:container("modal")
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
			self.sprite.s = sprite_by_label_and_method(input_label, "mouse")
	    end)
	    :build())
	row:add(
		box.builder("control_text_"..input_label)
		:layout{
			width = 6,
			height = 10,
			padding = box.layout.padding(2),
		}
		:text{
			content = {"/"},
			draw_properties = {
				wrap = "no_wrap",
			},
			text_color = text_color,
		}
		:build())
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
			self.sprite.s = sprite_by_label_and_method(input_label, "joypad")
	    end)
	    :build())
	return row
end

local function control_hint_row(
	input_label: InputLabel,
	menu_step_func: function(UIContextManager): menu_manager.MenuStep,
	default_hints: menu_types.ControlHints
): box.UIElement
	local row = box.builder("control_row_"..input_label)
		:direction("row")
		:container("strip")
		:build()

	row:add(control_hint_glyphs(input_label, nil))
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

			if menu_step ~= nil and menu_step.control_hints ~= nil then
				self.text.content = {
					menu_step.control_hints[input_label]
					and " "..menu_step.control_hints[input_label]
					or nil
				}
				return
			end

			if default_hints ~= nil then			
				self.text.content = {
					default_hints[input_label]
					and " "..default_hints[input_label]
					or nil
				}
				return
			end
		end)
	    :build())

	return row
end

function control_hints.centered_control_hint_row(
	input_label: InputLabel,
	message: string,
	text_color: box.UITextColor
): box.UIElement
	local row = box.builder("control_row_"..input_label)
		:direction("row")
		:container("strip")
		:build()

	row:add(box.spacer(1))
	row:add(control_hint_glyphs(input_label, text_color))
	row:add(
		box.builder("control_text_"..input_label)
		:direction"col"
		:container"strip"
		:padding(1)
		:text{
			content = {" "..message},
			draw_properties = {
				wrap = "no_wrap",
			},
			text_color = text_color,
		}
	    :build())
	row:add(box.spacer(1))

	return row
end

function control_hints.new(
	menu_step_func: function(UIContextManager): menu_manager.MenuStep,
	default_hints: menu_types.ControlHints
): box.UIElement
    local self = box.builder("control_hints")
		:direction("col")
		:container("block")
	    :build()

	self:add(control_hint_row("primary", menu_step_func, default_hints))
	self:add(control_hint_row("secondary", menu_step_func, default_hints))

	return self
end

return control_hints

