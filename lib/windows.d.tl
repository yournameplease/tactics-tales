--- @meta

--- Window Attributes
--- @class __WindowAttribs
--- @field autoclose? boolean
--- @field cursor? 0 | 1 | string | userdata
--- @field fullscreen? boolean
--- @field has_frame? boolean
--- @field height? integer
--- @field immortal? boolean
--- @field moveable? boolean
--- @field pausable? boolean
--- @field pwc_output? boolean
--- @field resizable? boolean
--- @field show_in_workspace? boolean
--- @field tabbed? boolean
--- @field title? string
--- @field video_mode? 0 | 3 | 4
--- @field wallpaper? boolean
--- @field width? integer
--- @field x? integer
--- @field y? integer
--- @field z? integer
global record __WindowAttribs
	autoclose: boolean
	cursor: integer | string | Userdata
	fullscreen: boolean
	has_frame: boolean
	height: integer
	immortal: boolean
	moveable: boolean
	pausable: boolean
	pwc_output: boolean
	resizable: boolean
	show_in_workspace: boolean
	tabbed: boolean
	title: string
	video_mode: integer
	wallpaper: boolean
	width: integer
	x: integer
	y: integer
	z: integer
end

--- Get the current display as a u8, 2d userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#get_display)
--- @return userdata
global get_display: function() : Userdata 

--- Set the draw target to a u8, 2d userdata
--- If ud is not provided, set the draw target to the current display
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#set_draw_target)
--- @param ud? userdata
global set_draw_target: function(ud?: Userdata) 

--- Gets the current draw target as a u8, 2d userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#get_draw_target)
--- @return userdata
global get_draw_target: function(): Userdata 

--- Create a window or set its attributes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#window)
--- @param width integer
--- @param height integer
--- @param attribs? __WindowAttribs
global window: function(width: integer, height: integer, attribs?: __WindowAttribs) 

--- Create a window or set its attributes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#window)
--- @param attribs? __WindowAttribs
-- global window: function(attribs: __WindowAttribs) 
