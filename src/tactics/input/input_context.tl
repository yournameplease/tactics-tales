local input = require("src/tactics/joypad")
local MenuMouseSelection = require("src/tactics/menu/menu_cursor").mouse_selection.MenuMouseSelection

local interface InputContext
	type: input.InputMethod
end

local record JoypadContext
	is InputContext
	where self.type == "joypad"
	joypad: input.Joypad
end

local record MouseContext
	is InputContext
	where self.type == "mouse"
	mouse: input.Mouse
	hovered: MenuMouseSelection
end

local input_context = {
	InputContext = InputContext,
	JoypadContext = JoypadContext,
	MouseContext = MouseContext,
}

function input_context.joypad(joypad: input.Joypad): InputContext
	local self: JoypadContext = {
		type = "joypad",
		joypad = joypad,
	}
	return self
end

function input_context.mouse(mouse: input.Mouse, hovered: MenuMouseSelection): InputContext
	local self: MouseContext = {
		type = "mouse",
		mouse = mouse,
		hovered = hovered,
	}
	return self
end

function input_context.handle_update(
	ctx: InputContext,
	update_joy: (function(joy: input.Joypad)),
    update_mouse: (function(input.Mouse, MenuMouseSelection)) 
)
    if ctx is input_context.JoypadContext then
        update_joy(ctx.joypad)
    elseif ctx is input_context.MouseContext then
        update_mouse(ctx.mouse, ctx.hovered)
    else
        error(ctx.type)
    end
end

return input_context
