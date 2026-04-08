---@brief
--- A UI panel that displays contextual control hints (e.g., "Select", "Back").

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local input_service = require("src.tactics.joypad")
local menu_types = require("src.tactics.menu.types")
local menu_manager = require("src.tactics.menu.menu_manager")

local control_hints = {}

local type ActionSprites = { input_service.InputAction: integer }

local SPRITE_OFFSETS <total>: ActionSprites = {
    ["BUTTON_A"] = 0,
    ["BUTTON_B"] = 1,
    ["SHOULDER_L"] = 4,
    ["SHOULDER_R"] = 5,
}

local HAS_MOUSE_SPRITE <total>: { input_service.InputAction: boolean } = {
    ["BUTTON_A"] = true,
    ["BUTTON_B"] = true,
    ["SHOULDER_L"] = false,
    ["SHOULDER_R"] = false,
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
	input_label: input_service.InputAction,
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

local function control_hint_glyphs(
	input_label: input_service.InputAction,
	text_color: box.UITextColor
): box.UIElement
	local row = box.builder("control_row_"..input_label)
		:direction("row")
		:container("modal")
		:build()

	if HAS_MOUSE_SPRITE[input_label] then
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
		    :on_update(function(self: box.UIElement, _state: UIContextManager)
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
	else
		row:add(
			box.builder("no_mouse_spacer_"..input_label)
			:layout{
				width = 15,
				height = 10,
				padding = box.layout.padding(2),
			}
			:build())
	end
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
	    :on_update(function(self: box.UIElement, _state: UIContextManager)
			self.sprite.s = sprite_by_label_and_method(input_label, "joypad")
	    end)
	    :build())
	return row
end

local function control_hint_row(
	input_label: input_service.InputAction,
	menu_step_func: function(UIContextManager): menu_manager.MenuStep,
	default_hints: menu_types.MenuActions
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

			if menu_step ~= nil and menu_step.menu_actions ~= nil then
				self.text.content = {
					menu_step.menu_actions[input_label]
					and " "..menu_step.menu_actions[input_label].description
					or nil
				}
				return
			end

			if default_hints ~= nil then			
				self.text.content = {
					default_hints[input_label]
					and " "..default_hints[input_label].description
					or nil
				}
				return
			end
		end)
	    :build())

	return row
end

function control_hints.centered_control_hint_row(
	input_label: input_service.InputAction,
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
	default_hints: menu_types.MenuActions
): box.UIElement
    local self = box.builder("control_hints")
		:direction("col")
		:container("block")
	    :build()

	self:add(control_hint_row("BUTTON_A", menu_step_func, default_hints))
	self:add(control_hint_row("BUTTON_B", menu_step_func, default_hints))
	self:add(control_hint_row("SHOULDER_L", menu_step_func, default_hints))
	self:add(control_hint_row("SHOULDER_R", menu_step_func, default_hints))

	return self
end

return control_hints

