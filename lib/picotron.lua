--- @meta

--- personal global helpers, not part of picotron

function todo(message)
	error("Function is not implemented!"..(message and " "..message or ""))
end

function unexpected(state)
	error("Received an unexpected state: "..(state and message or "nil"))
end


--- container for all Picotron functions
local pt = {}


--- @class __MenuItem
--- @field id? integer Unique identifier, used to sort items (otherwise order added is used)
--- @field label? string | function User facing label
--- @field shortcut? string Drawn right justified in the menu
--- @field greyed? boolean Greyed out item (use for ---)
--- @field action? function Callback on select -- param b is the button pressed (left or right)
--- @field divider? boolean Is item a divider
-- global record __MenuItem
-- 	id: integer 
-- 	label: string 
-- 	shortcut: string 
-- 	greyed: boolean 
-- 	action: function 
-- 	divider: boolean 	
-- end

--- Adds a menu item
--- If m is nil, reset the menu
--- View implementation in /system/lib/app_menu.lua
--- @param m? __MenuItem
-- global menuitem: function(m?: __MenuItem) 

--- Adds a menu item
--- id is the numerical id
--- label is the label for the menu item
--- action is a callback for when the item is pressed -- param b is the button pressed (left or right)
--- View implementation in /system/lib/app_menu.lua
--- @param id integer
--- @param label string | function
--- @param action function
function pt.menuitem(id, label, action) 
	menuitem(id , label, action)
end
--- @meta

--- Plays a sound effect.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sfx)
--- @param n integer The index of the sound effect to play (0-63). -1 stops the sound effect on the channel. -2 stops the sound effect and clears the channel state.
--- @param channel? integer The channel to play the sound effect on (0-15).
--- @param offset? integer The offset in the sound effect to start playing from (0-63 in notes).
--- @param length? integer The length of the sound effect to play in notes (0-63).
--- @param pan? integer The panning of the sound effect (-128 to 127).
--- @param mix_volume? integer The volume of the sound effect (0-255). Takes priority over the value at `0x553a`.
function pt.sfx(n, channel, offset, length, pan, mix_volume)
	sfx(n, channel, offset, length, pan, mix_volume)
end

--- Plays music starting from pattern n.
--- If n is -1, stop music
--- fade_len is in ms (default 0)
--- channel_mask is bitfield that specifies which channels to reserve for music only, low bits first
--- @param n integer
--- @param fade_len? integer
--- @param channel_mask? integer
function pt.music(n, fade_len, channel_mask, base_addr, tick_offset)
	music(n, fade_len, channel_mask, base_addr, tick_offset)
end

--- This provides low level control over a channel. It is useful in more niche situations, like audio authoring tools and size-coding.
--- Internally this is what is used to play each row of a sfx when one is active. Use 0xff to indicate an attribute should not be altered.
---     pitch     channel pitch (default 48 -- middle C)
---     inst      instrument index (default 0)
---     vol       channel volume (default 64)
---     effect    channel effect (default 0)
---     effect_p  effect parameter (default 0)
---     channel   channel index (0..15 -- default 0)
---     retrig    (boolean) force retrigger -- default to false
---     panning   set channel panning (-128..127)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#note)
--- @param pitch integer
--- @param inst integer
--- @param vol integer
--- @param effect integer
--- @param effect_p integer
--- @param channel integer
--- @param retrig boolean
--- @param panning integer
function pt.note(pitch, inst, vol, effect, effect_p, channel, retrig, panning) 
	note(pitch, inst, vol, effect, effect_p, channel, retrig, panning)
end


--- Create a coroutine for a function
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#COCREATE)
--- @param func function
--- @return thread
function pt.cocreate(func)
	return cocreate(func)
end

--- Run or continue the coroutine c. Parameters are passed to the function
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#CORESUME)
--- @param c thread
--- @param ... any
--- @return boolean error
--- @return ... any
function pt.coresume(c, ...)
	return coresume(c, ...)
end

--- Checks the status of a coroutine
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#COSTATUS)
--- @param c thread
--- @return string
function pt.costatus(c)
	return costatus(c)
end

--- Yield the coroutine back to the caller
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#YIELD)
--- @param ... any
function pt.yield(...) 
	yield(...)
end
--- @meta

--- @class __FileMetadata
--- @field created string
--- @field modified string
--- @field pod_format? string
--- @field revision? integer
-- global record __FileMetadata
-- 	created: string
-- 	modified: string
-- 	pod_format: string
-- 	revision: integer
-- end

--- Change the current working directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cd)
--- @param path string
function pt.cd(path) 
	cd(path)
end

--- Gets the file type, size, and origin
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fstat)
--- @param path string
--- @return string | nil type
--- @return number | nil size
--- @return string | nil origin
function pt.fstat(path)
	return fstat(path)
end

--- Converts a relative path to an absolute path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fullpath)
--- @param filename string
--- @return string
function pt.fullpath(filename)
	return fullpath(filename)
end

--- Lists the contents of a folder
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ls)
--- @param path? string
--- @return string[]
function pt.ls(path)
	return ls(path)
end

--- Copy a file from src to dest. Folders are copied recursively and the dest is overwritten.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cp)
--- @param src string
--- @param dest string
function pt.cp(src, dest) 
	cp(src, dest)
end

--- Move a file from src to dest. Folders are copied recursively and the dest is overwritten.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mv)
--- @param src string
--- @param dest string
function pt.mv(src, dest) 
	mv(src, dest)
end

--- Delete a file or folder (recursive)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#rm)
--- @param filename string
function pt.rm(filename) 
	rm(filename)
end

--- Return the present working directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pwd)
--- @return string
function pt.pwd()
	return pwd()
end

--- Read a lua object from a file
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fetch)
--- @param filename string
--- @return any
--- @return __FileMetadata?
function pt.fetch(filename)
	return fetch(filename)
end

--- Store a lua object to a file
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#store)
--- @param filename string
--- @param object table | string | userdata | boolean | number
--- @param metadata? __FileMetadata
function pt.store(filename, object, metadata) 
	store(filename, object, metadata)
end

--- Fetch just the metadata of a path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fetch_metadata)
--- @param filename string
--- @return __FileMetadata | nil
function pt.fetch_metadata(filename)
	return fetch_metadata(filename)
end

--- Store just the metadata of a path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#store_metadata)
--- @param filename string
--- @param metadata __FileMetadata
function pt.store_metadata(filename, metadata) 
	store_metadata(filename, metadata)
end

--- Create a directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mkdir)
--- @param name string
function pt.mkdir(name) 
	mkdir(name)
end

-- --- @param filename string
-- function include(filename)
--     require(filename)
-- end

--- Mounts a folder. Creates a link from origin to target
--- View implementation in /system/lib/fs.lua
--- @param target string
--- @param origin string
function pt.mount(target, origin) 
	mount(target, origin)
end

--- Loads and runs a lua file like a function.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#include)
--- @param filename string The path to the file relative to the working directory. Must include the file extension.
--- @return any? #The return value of the file, if any.
function pt.include(filename)
	return include(filename)
end
--- @meta

--- Changes the video mode
--- 0 is 480x720
--- 3 is 240x135
--- 4 is 160x90
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#vid)
--- @param mode 0 | 3 | 4
function pt.vid(mode) 
	vid(mode)
end

--- Clears the screen and resets the clipping rectangle
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cls)
--- @param col? integer
function pt.cls(col) 
	cls(col)
end

--- Prints text on screen
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#print)
--- @param value any The object to print.
--- @param x? integer The x coordinate to print at.
--- @param y? integer The y coordinate to print at.
--- @param col? integer The color index to print in.
--- @return integer new_x The x coordinate of the next character to be printed.
--- @return integer new_y The y coordinate of the next character to be printed.
function pt.print(value, x, y, col)
	return print(value, x, y, col)
end

--- Sets the clipping rectangle for drawing operations.
--- If clip_previous is set, the new region will be clipped by the old region
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#clip)
--- @param x integer
--- @param y integer
--- @param w integer
--- @param h integer
--- @param clip_previous? boolean
function pt.clip(x, y, w, h, clip_previous) 
	clip(x, y, w, h, clip_previous)
end

--- Reset clipping region
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#clip)
--- @return integer x
--- @return integer y
--- @return integer w
--- @return integer h
-- global clip: function()

--- Sets the pixel to at x, y to the color index 0 to 63
--- If color is not specified, uses the current draw color instead
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pset)
--- @param x integer
--- @param y integer
--- @param col? integer
function pt.pset(x, y, col) 
	pset(x, y, col)
end

--- Returns the color of the pixel at x, y
--- Returns 0 if out of bounds
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pget)
--- @param x integer
--- @param y integer
--- @return integer
function pt.pget(x, y)
	return pget(x, y)
end

-- These are in the docs, but they don't appear to be implemented
-- In any case, sprites are just userdata, so you can do userdata:get()
-- and userdata:set() if I'm understanding this correctly
-- function sset(x, y, col) end
-- function sget(x, y) end

--- Get the value of a sprite n's flag f (0-7)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fget)
--- @param n integer
--- @param f integer
--- @return boolean
-- global fget: function(n: integer, f: integer)
function pt.fget_one(n, f)
	return fget(n, f)
end

function pt.fget(n)
	return fget(n)
end

--- Set the value of a sprite n's flag f (0-7)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fset)
--- @param n integer
--- @param f integer
--- @param val boolean
function pt.fset(n, f, val) 
	fset(n, f, val)
end

--- Set the cursor position
--- If color is specified, also set the current color
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cursor)
--- @param x integer
--- @param y integer
--- @param col? integer
function pt.cursor(x, y, col) 
	cursor(x, y, col)
end

--- Set the current color
--- If color is not specified, set the current color to 6
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#color)
--- @param col integer
function pt.set_color(col) 
	color(col)
end

function pt.reset_color()
	color()
end

--- Set a screen offset of -x, -y for all drawing operations
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#camera)
--- @param x integer
--- @param y integer
--- @return integer x
--- @return integer y
function pt.set_camera(x, y)
	return camera(x, y)
end

--- Reset the camera offset
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#camera)
--- @return integer x
--- @return integer y
function pt.reset_camera()
	camera()
end

--- Draw a circle at x, y with radius r
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#circ)
--- @param x integer
--- @param y integer
--- @param r integer
--- @param col? integer
function pt.circ(x, y, r, col) 
	circ(x, y, r, col)
end

--- Draw a filled circle at x, y with radius r
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#circfill)
--- @param x integer
--- @param y integer
--- @param r integer
--- @param col? integer
function pt.circfill(x, y, r, col) 
	circfill(x, y, r, col)
end

--- Draw an ellipse within the given rectangle
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#oval)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
function pt.oval(x0, y0, x1, y1, col) 
	oval(x0, y0, x1, y1, col)
end

--- Draw a filled ellipse within the given rectangle
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ovalfill)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
function pt.ovalfill(x0, y0, x1, y1, col) 
	ovalfill(x0, y0, x1, y1, col)
end

--- Draw a line from (x0, y0) to (x1, y1)
--- If (x1, y1) are not given the end of the last line will be used
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#line)
--- @param x0 integer
--- @param y0 integer
--- @param x1? integer
--- @param y1? integer
--- @param col? integer
function pt.line(x0, y0, x1, y1, col) 
	line(x0, y0, x1, y1, col)
end

--- The next call to line(x1, y1) will set the endpoints without drawing
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#line)
-- global line: function()  

--- Draw a rectangle within the given points
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#rect)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
function pt.rect(x0, y0, x1, y1, col) 
	rect(x0, y0, x1, y1, col)
end
function pt.rrect(x, y, w, h, radius, col) 
	rrect(x, y, w, h, radius, col)
end

--- Draw a filled rectangle within the given points
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#rectfill)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
function pt.rectfill(x0, y0, x1, y1, col) 
	rectfill(x0, y0, x1, y1, col)
end
function pt.rrectfill(x, y, w, h, radius, col) 
	rrectfill(x, y, w, h, radius, col)
end

--- Remaps one color index to produce another.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pal)
--- @param c0 integer The index to remap.
--- @param c1 integer The index to map c0 to.
--- @param p? 0 | 1 0 to swap during drawing, 1 to swap the entire screen. Defaults to 0.
function pt.set_pal(c0, c1, p) 
	pal(c0, c1, p)
end
function pt.reset_pal() 
	pal()
end

--- Sets the ARGB color value for the given color index.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_gfx_pipeline.html#Display_Palettes)
--- @param c0 integer The index to change the color of.
--- @param argb integer The ARGB color value to set as a 32-bit integer, with the alpha channel in the highest byte.
--- @param p 2
-- global pal: function(c0: integer, argb: integer, p: integer) 

--- Resets the color tables back to their defaults.
--- @param p 0
-- global pal: function(p: integer) 

--- Resets the indexed display palettes back to their defaults.
--- @param p 1
-- global pal: function(p: integer) 

--- Resets all palettes and color tables back to their defaults.
-- global pal: function()  

--- Set the transparency of a color
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#palt)
--- @param c integer
--- @param is_transparent boolean
function pt.set_palt(c, is_transparent) 
	palt(c, is_transparent)
end
function pt.reset_palt(c) 
	palt(c)
end

--- Set the transparency of all colors
--- c is a bitfield representing the transparency of all 64 colors
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#palt)
--- @param c? integer
-- global palt: function(c: integer) 

--- Draws a sprite on the screen
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#spr)
--- @param s integer | userdata
--- @param x? integer
--- @param y? integer
--- @param flip_x? boolean
--- @param flip_y? boolean
function pt.spr(s, x, y, flip_x, flip_y) 
	spr(s, x, y, flip_x, flip_y)
end

--- Crops a sprite to a source rectangle and draws it stretched to fit a destination rectangle on the current draw target.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sspr)
--- @param s integer | userdata The sprite to draw. This can be a sprite index or a u8 userdata object.
--- @param sx? integer The x coordinate of the top left corner of the source rectangle. Defaults to 0.
--- @param sy? integer The y coordinate of the top left corner of the source rectangle. Defaults to 0.
--- @param sw? integer The width of the source rectangle. Defaults to the width of the sprite.
--- @param sh? integer The height of the source rectangle. Defaults to the height of the sprite.
--- @param dx? integer The x coordinate of the top left corner of the destination rectangle. Defaults to 0.
--- @param dy? integer The y coordinate of the top left corner of the destination rectangle. Defaults to 0.
--- @param dw? integer The width of the destination rectangle. Defaults to sw.
--- @param dh? integer The height of the destination rectangle. Defaults to sh.
--- @param flip_x? boolean Whether to flip the sprite horizontally. Defaults to false.
--- @param flip_y? boolean Whether to flip the sprite vertically. Defaults to false.
function pt.sspr(s, sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y) 
	sspr(s, sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y)
end

--- Set a 4x4 fill pattern using Pico-8 style fill patterns
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fillp)
--- @param p integer
--- @param ... integer
-- global fillp: function(p?: integer, ...: integer) 
function pt.fillp(...) 
	fillp(...)
end

--- Get the sprite for a given index
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#get_spr)
--- @param index integer
--- @return userdata
function pt.get_spr(index)
	return get_spr(index)
end

--- Set the sprite for a given index
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#set_spr)
--- @param index integer
--- @param ud userdata
function pt.set_spr(index, ud) 
	set_spr(index, ud)
end

--- Copies the graphics buffer to the screen, then syncronizes to the next frame
--- [View Online](https://pico-8.fandom.com/wiki/Flip)
--- @param flags? integer
function pt.flip(flags) 
	flip(flags)
end
-- --- @meta

-- --- @class __GUI_PROPS
-- --- @field height? integer
-- --- @field height_rel? integer
-- --- @field width? integer
-- --- @field width_rel? integer
-- --- @field x? integer
-- --- @field y? integer
-- --- @field z? integer
-- --- @field click? function
-- --- @field release? function
-- --- @field tap? function
-- --- @field update? function
-- --- @field draw? function
-- __GUI_PROPS = {}

-- --- @class __GUI: __GUI_PROPS
-- __GUI = {}

-- --- @class __GUI_ED_PROPS: __GUI_PROPS
-- --- @field bgcol? integer
-- --- @field fgcol? integer
-- __GUI_ED_PROPS = {}

-- --- @class __GUI_ED: __GUI_ED_PROPS
-- __GUI_ED = {}

-- --- @param head_el? __GUI_PROPS
-- --- @return __GUI
-- --- Create a GUI
-- global create_gui: function(head_el: any) 

-- --- @class __GUI
-- --- Draws all GUI elements
-- global __GUI: function:draw_all: any() 

-- --- @class __GUI
-- --- Updates all GUI elements
-- global __GUI: function:update_all: any() 

-- --- @class __GUI
-- --- @param focus boolean
-- --- Sets keyboard focus
-- global __GUI: function:set_keyboard_focus: any(focus) 

-- --- @class __GUI
-- --- @param head_el __GUI_PROPS
-- --- @return __GUI
-- global __GUI: function:attach: any(head_el) 

-- --- @class __GUI
-- --- @param head_el? __GUI_ED_PROPS
-- --- @return __GUI_ED
-- --- Attaches a text editor to the GUI
-- global __GUI: function:attach_text_editor: any(head_el) 

-- --- @class __GUI_ED
-- --- @param text string
-- --- Set the text editor's current text
-- global __GUI_ED: function:set_text: any(text) 

-- --- @class __GUI_ED
-- --- @param column integer
-- --- @param line integer
-- --- Set the text editor's cursor position
-- global __GUI_ED: function:set_cursor: any(column, line) 

-- --- @class __GUI_ED
-- --- @return string[]
-- --- Set the text editor's current text
-- global __GUI_ED: function:get_text: any() 
--- @meta

--- Get the state of the button for the specified player
--- 0 1 2 3     LEFT RIGHT UP DOWN
--- 5 6         Buttons: O X
--- 7           MENU
--- 8           reserved
--- 9 10 11 12  Secondary Stick L,R,U,D
--- 12 13       Buttons (not named yet!)
--- 14 15       SL SR
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#btn)
--- @param button integer
--- @param player? integer
--- @return number | false
-- global btn: function(button: integer, player?: integer)
function pt.btn(button, player)
	return btn(button, player)
end

--- Get the state of a button held down.
--- By default, a button press repeats after 30 frames, and once again every 8 frames
--- 0 1 2 3     LEFT RIGHT UP DOWN
--- 5 6         Buttons: O X
--- 7           MENU
--- 8           reserved
--- 9 10 11 12  Secondary Stick L,R,U,D
--- 12 13       Buttons (not named yet!)
--- 14 15       SL SR
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#btnp)
--- @param button integer
--- @param player? integer
--- @return number | false
-- global btnp: function(button: integer, player?: integer)
function pt.btnp(button, player)
	return btnp(button, player)
end

--- Get the state of a key
--- If raw is set, ignore the keyboard layout
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#key)
--- @param k string
--- @param raw? boolean
--- @return boolean
function pt.key(k, raw)
	return key(k, raw)
end

--- Get the state of a key held down
--- If raw is set, ignore the keyboard layout
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#keyp)
--- @param k string
--- @param raw? boolean
--- @return boolean
function pt.keyp(k, raw)
	keyp(k, raw)
end

--- Reset the state of a key until the end of frame
--- View implementation in /system/lib/events.lua
--- @param k string
function pt.clear_key(k) 
	clear_key(k)
end

--- Check if text is waiting to be read with `readtext()`
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peektext)
--- @return boolean
function pt.peektext()
	return peektext()
end

--- Read the next peice of text waiting
--- If clear is set, discard remaining text
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#readtext)
--- @param clear? boolean
function pt.readtext(clear) 
	return readtext(clear)
end

--- Gets the current location and state of the mouse
--- If new_mx and new_my are set, move the mouse to that position
--- mouse_b is a bitfield.
---     0x1 means left mouse button
---     0x2 means right mouse button
---     0x4 means middle mouse button
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mouse)
--- @param new_mx? number
--- @param new_my? number
--- @return number mouse_x
--- @return number mouse_y
--- @return integer mouse_b
--- @return number wheel_x
--- @return number wheel_y
function pt.get_mouse()
	return mouse()
end
function pt.set_mouse(new_mx, new_my)
	mouse(new_mx, new_my)
end

--- Requests to capture the mouse to control speed and move_sensitivity
--- event_sensitivity determines how fast dx and dy change
---     1 - 4; 1.0 means once per Picotron pixel
--- move_sensitivity determines how fast the cursor moves
---     1 - 4; 1.0 means the cursor continues to move at the same speed
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mouselock)
--- @param lock boolean
--- @param event_sensitivity number
--- @param move_sensitivity number
--- @return number dx
--- @return number dy
function pt.mouselock(lock, event_sensitivity, move_sensitivity)
	return mouselock(lock, event_sensitivity, move_sensitivity)
end

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#map)
--- @param tile_x integer
--- @param tile_y integer
--- @param sx? integer
--- @param sy? integer
--- @param tiles_x? integer
--- @param tiles_y? integer
--- @param p8layers? integer
--- @param tile_w? integer
--- @param tile_h? integer
-- global map: function(tile_x: any, tile_y: any, sx: any, sy: any, tiles_x: any, tiles_y: any, p8layers: any, tile_w: any, tile_h: any) 

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#map)
--- @param src userdata
--- @param tile_x any
--- @param tile_y any
--- @param sx? any
--- @param sy? any
--- @param tiles_x? any
--- @param tiles_y? any
--- @param p8layers? any
--- @param tile_w? any
--- @param tile_h? any
function pt.map(src, tile_x, tile_y, sx, sy, tiles_x, tiles_y, p8layers, tile_w, tile_h) 
	map(src, tile_x, tile_y, sx, sy, tiles_x, tiles_y, p8layers, tile_w, tile_h)
end

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mget)
--- @param x any
--- @param y any
function pt.mget(x, y) 
	mget(x, y)
end

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mset)
--- @param x any
--- @param y any
--- @param val any
function pt.mset(x, y, val) 
	mset(x, y, val)
end

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#tline3d)
--- @param src_ud any
--- @param x0 any
--- @param y0 any
--- @param x1 any
--- @param y1 any
--- @param u0 any
--- @param v0 any
--- @param u1 any
--- @param v1 any
--- @param w0 any
--- @param w1 any
--- @param flags any
function pt.tline3d(src_ud, x0, y0, x1, y1, u0, v0, u1, v1, w0, w1, flags) 
	tline3d(src_ud, x0, y0, x1, y1, u0, v0, u1, v1, w0, w1, flags)
end
--- @meta

--- Returns the minimum of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MIN)
--- @param x number
--- @param y number
--- @return number
-- global min: function(x: number, y: number)
function pt.min(x, y)
	return min(x, y)
end

--- Returns the maximum of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MAX)
--- @param x number
--- @param y number
--- @return number
-- global max: function(x: number, y: number)
function pt.max(x, y)
	return max(x, y)
end

--- Returns the middle value of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MID)
--- @param x number
--- @param y number
--- @param z number
--- @return number
-- global mid: function(x: number, y: number, z: number)
function pt.mid(x, y, z)
	return mid(x, y, z)
end

--- Returns the nearest integer at or below a number
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#FLR)
--- @param x number
--- @return integer
function pt.flr(x)
	return flr(x)
end

--- Returns the nearest integer at or above a number
--- [View Online](https://pico-8.fandom.com/wiki/Ceil)
--- @param val number
--- @return integer
function pt.ceil(val)
	return ceil(val)
end

--- Generate a random number under the given limit
--- or a random element from the table
--- Limit is 1 if not set
--- [View Online](https://pico-8.fandom.com/wiki/Rnd)
--- @param limit? number
--- @return number
function pt.rnd(limit)
	return rnd(limit)
end

--- Generate a random number under the given limit
--- or a random element from the table
--- [View Online](https://pico-8.fandom.com/wiki/Rnd)
--- @param tbl table
--- @return any
-- global rnd: function(tbl: number)

--- Initializes the random number generator with an explicit seed value
--- [View Online](https://pico-8.fandom.com/wiki/Srand)
--- @param val number
function pt.srand(val)
	return srand(val)
end

--- Converts a value to a number
--- @param val any
--- @param format_flags? integer
--- @return number
function pt.tonum(val, format_flags)
	return tonum(val, format_flags)
end

--- Returns the absolute value of a number
--- [View Online](https://pico-8.fandom.com/wiki/Abs)
--- @param n number
--- @return number
-- global abs: function(n: number)
function pt.abs(n)
	return abs(n)
end
function pt.absf(n)
	return abs(n)
end

--- Returns the sign of a number. 1 for positive, -1 for negative
--- [View Online](https://pico-8.fandom.com/wiki/Sgn)
--- @param n number
--- @return -1 | 1
function pt.sgn(n)
	return sgn(n)
end

--- Calculates the arctangent of dx/dy formed by the vector on the unit circle.
--- The result is adjusted to represent the full circle.
--- [View Online](https://pico-8.fandom.com/wiki/Atan2)
function pt.atan2(dx, dy)
	return atan2(dx, dy)
end

--- Calculates the sin of an angle
--- Uses a range of 0.0 to 1.0 to represent the angle. Sometimes called turns.
--- Example: 180 degrees or pi radians is 0.5 turns.
--- [View Online](https://pico-8.fandom.com/wiki/Sin)
--- @param angle number
--- @return number
function pt.sin(angle)
	return sin(angle)
end

--- Calculates the sin of an angle
--- Uses a range of 0.0 to 1.0 to represent the angle. Sometimes called turns.
--- Example: 180 degrees or pi radians is .5 turns.
--- [View Online](https://pico-8.fandom.com/wiki/Cos)
--- @param angle number
--- @return number
function pt.cos(angle)
	return cos(angle)
end

--- Calculates the square root of a number
--- [View Online](https://pico-8.fandom.com/wiki/Sqrt)
--- @param n number
--- @return number
function pt.sqrt(n)
	return sqrt(n)
end
--- @meta

--- Read a byte from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function pt.peek(addr, n)
	return peek(addr, n)
end

--- Read an i16 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek2)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function pt.peek2(addr, n)
	return peek2(addr, n)
end

--- Read an i32 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek4)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function pt.peek4(addr, n)
	return peek4(addr, n)
end

--- Read an i64 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek4)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function pt.peek8(addr, n)
	return peek8(addr, n)
end

--- Write a byte to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke)
--- @param addr integer
--- @param ... integer
function pt.poke(addr, ...)
	poke(addr, ...)
end

--- Write an i16 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke2)
--- @param addr integer
--- @param ... integer
function pt.poke2(addr, ...)
	poke2(addr, ...)
end

--- Write an i32 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke4)
--- @param addr integer
--- @param ... integer
function pt.poke4(addr, ...)
	poke4(addr, ...)
end

--- Write an i64 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke4)
--- @param addr integer
--- @param ... integer
function pt.poke8(addr, ...)
	poke8(addr, ...)
end

--- Copy len bytes from source address to destination address
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memcpy)
--- @param dest_addr integer
--- @param source_addr integer
--- @param len integer
function pt.memcpy(dest_addr, source_addr, len) 
	memcpy(dest_addr, source_addr, len)
end

--- Write the byte val to destination address for len bytes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memset)
--- @param dest_addr integer
--- @param val integer
--- @param len integer
function pt.memset(dest_addr, val, len) 
	memset(dest_addr, val, len)
end
--- @meta

--- Gets a binary string encoding the value
--- Flags determine the encoding
---     0x0 - default
---     0x1 - pxu - RLE style compression
---     0x2 - lz4 compression
---     0x3 - base64
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pod)
--- @param val table | string | userdata | boolean | number
--- @param flags? integer
--- @param metadata? table
--- @return string | nil
function pt.pod(val, flags, metadata)
	return pod(val    , flags, metadata)
end

--- Gets the decoded value and metadata from a POD string
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#unpod)
--- @param val string
--- @return table | string | userdata | boolean | number | nil content
--- @return table metadata
function pt.unpod(val)
	return unpod(val)
end
--- @meta

--- @class Socket
-- sock = {}

--- Create a socket.
--- `addr` is a string consisting of the protocol (`tcp://` or `udp://`), the ip address, followed by a port number ":1234". ipv6 addresses should be enclosed in square brackets.
--- 
--- To create a socket that listens to any incoming traffic on a given port, use * for the address.
--- 
--- A socket with remote hosts writing (or connecting to) that port can then be accepted using sock:accept(). Listener sockets can not be created while a process is sandboxed. i.e. BBS carts can proactively connect to a particular address, but can not receive connections from arbitrary sources.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#socket)
--- @param addr string The address of the socket, starting with `tcp://` or `udp://`, followed by ipv4 address, ipv6 address, a domain name, or a wildcard `*`, ending with a port separated by a colon.
--- @return Socket socket A newly opened socket.
-- global socket: function(addr: any) 

--- Read a string from a socket. This function is not blocking; it will return nothing when there is no data available on the socket.
--- 
--- Returns the number of bytes written, or nil followed by an error message string.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_read)
--- @class Socket
--- @return string msg
-- global sock: function:read: any() 

--- Write string str to socket.

--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_write)
--- @class Socket
--- @param str string The string to write to the socket.
--- @return number bytes_written The number of bytes written to the socket.
-- global sock: function:write: any(str) 

--- Close the connection if there is one.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_close)
--- @class Socket
-- global sock: function:close: any() 

--- Returns a string describing the sockets status
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_status)
--- @class Socket
--- @return "ready" | "listening" | "closed" | "closed by peer" | "disconnected" | "invalid"
-- global sock: function:status: any() 

--- This can be used with sockets that are listening to all traffic on a given port. When a new connection is made with tcp, or a UDP message is receieved from a new address+port, :accept() will return a new socket that can be used to communicate with that particular client, or nil if none found.
--- 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sock_accept)
--- @class Socket
--- @return Socket client_socket
-- global sock: function:accept: any() 
--- @meta

--- @class string
-- string = {}

--- Get the extension of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
-- global string: function:ext: any() 

--- Get the basename (filename and extension) of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
-- global string: function:basename: any() 

--- Get the path of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
-- global string: function:path: any() 

--- Get the hloc(?) of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
-- global string: function:hloc: any() 

--- Get the directory of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
-- global string: function:dirname: any() 

--- Get the protocol (e.g. http) of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
-- global string: function:prot: any() 

--- Converts 1 or more ordinal character codes to a string
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#chr)
--- @param val integer
--- @param ... integer
-- global chr: function(val: any, ...: any) 
function pt.chr(val)
	return chr(val)
end 

--- Convert 1 or more characters from a string to ordinal character codes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ord)
--- @param str string
--- @param index? integer
--- @param num_results? integer
--- @return (integer | nil) ...
-- global ord: function(str: any, index: any, num_results: any) 

--- Get the substring from pos0 to pos1 (inclusive)
--- If pos1 is not specified, return substring from pos0 to end of string
--- If pos1 is not a number, return a single character at pos0
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sub)
--- @param str string
--- @param pos0 integer
--- @param pos1? integer | boolean
--- @return string
function pt.sub(str, pos0, pos1)
	return sub(str, pos0, pos1 )
end

--- Converts a value to a string.
--- @param value any The value to convert.
--- @param as_hex? boolean If true, numbers will be converted to a hexidecimal string. Non-numbers will convert to 0x0. Decimal numbers will error.
--- @return string The string representation of the value.
-- global tostr: function(value: any, as_hex: any) 

--- Splits a string on a separator
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#split)
--- @param str string
--- @param separator? string
--- @param convert_numbers? true
--- @return number[]
function pt.split(str, separator)
	return split(str, separator, false)
end 

--- Splits a string on a separator
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#split)
--- @param str string
--- @param separator? string
--- @param convert_numbers? false
--- @return string[]
-- global split: function(str: any, separator: any, convert_numbers: any) 
-- string.split = split

function pt.type(val)
	return type(val)
end

--- Create a string encoding all the information needed to get from str0 to str1.
--- The delta can be used with apply_delta to produce str1 given only str0.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#create_delta)
--- @param str0 string
--- @param str1 string
--- @return string
-- global create_delta: function(str0: any, str1: any) 

--- Apply a delta created with create_delta to str0. This will produce str1.
--- str0 must be the exactly the same as the string used to create the delta; otherwise apply_delta returns nil.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#apply_delta)
--- @param str0 string
--- @param delta string
--- @return string | nil
-- global apply_delta: function(str0: any, delta: any) 
--- @meta

--- Environment Properties
--- @class __Environment
--- @field argv? string[]
--- @field immortal? boolean
--- @field parent_pid? integer
--- @field path? string
--- @field print_to_proc_id? integer
--- @field prog_name? string
--- @field title? string
--- @field window_attribs? __WindowAttribs
-- global record __Environment 
-- 	argv: {string}
-- 	immortal: boolean
-- 	parent_pid: integer
-- 	path: string
-- 	print_to_proc_id: integer
-- 	prog_name: string
-- 	title: string
-- 	window_attribs: __WindowAttribs
-- end




-- Defining _ENV causes these definitions in system.lua to be ignored
-- @type any
-- _ENV = {}

--- Gets the environment variables given to the process at its creation
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#env)
--- @return __Environment
function pt.env()
	return env()
end

--- Exits the program
--- @param exit_code? integer
function pt.exit(exit_code) 
	exit(exit_code)
end

--- Prints text to the host system's console
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#printh)
--- @param value any
function pt.printh(value) 
	printh(value)
end

--- @param filename string
--- @param env? __Environment
function pt.create_process(filename, env) 
	create_process(filename, env)
end

--- Stop the cart and optionally print a message
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#stop)
--- @param message? string
function pt.stop(message) 
	stop(message)
end

--- If condition is false, stop the cart and print a message
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#assert)
--- @param condition boolean
--- @param message? string
-- global assert: function(condition: boolean, message: string) 

--- Get the number of seconds elapsed since the cartridge was run
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#time)
--- @return number
function pt.time()
	return time()
end

--- Get the number of seconds elapsed since the cartridge was run
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#t)
--- @return number
function pt.t()
	return t()
end

--- : anyGet the current date and time formatted using Lua's standard date 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#date)
--- @param format? string
--- @param t? integer | string
--- @param delta? number
--- @return string
function pt.date(format, t, delta)
	date(format, t , delta)
end

--- Set the system clipboard
--- @param text string
function pt.set_clipboard(text) 
	set_clipboard(text)
end

--- Get the system clipboard
--- @return string
function pt.get_clipboard()
	return get_clipboard()
end

--- Adds an event listener
--- @param event string
--- @param callback function
function pt.on_event(event, callback) 
	on_event(event, callback)
end

--- Sends an event to a process
--- @param pid integer
--- @param event table
function pt.send_message(pid, event) 
	send_message(pid, event)
end

--- Get the current process id
--- @return integer
function pt.pid()
	return pid()
end

--- Create a notification toast
--- @param message string
function pt.notify(message) 
	notify(message)
end

-- should stat(n) return any? i think it always returns a number, but that might not always be true

--- Returns information about the current runtime environment
--- If addr is specified, copy the result to addr. This isn't fully documented, see [Querying Mixer State](https://pico-8.fandom.com/wiki/Stat?fandom=allow)
--- [View Online](https://pico-8.fandom.com/wiki/Stat)
--- @param id integer
--- @param addr? integer
--- @return any
function pt.stat(id, addr) 
	return stat(id, addr)
end

--- Get a property from the current theme (/ram/shared/theme.pod)
--- @param which string
--- @return any
function pt.theme(which) 
	return theme(which)
end

--- Opens a file using the system file associations (/system/util/open.lua)
--- @param file string
function pt.open(file) 
	open(file)
end
--- @meta

--- Add an element to a table
--- If index is not specified, the item will be added to the end of the table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#add)
--- @param table table
--- @param value any
--- @param index? number
function pt.add(table, value, index) 
	add(table, value, index)
end

--- Delete the first instance of value in table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#del)
--- @param table table
--- @param value any
--- @return any | nil
function pt.del(table, value)
	return del(table, value)
end

--- Delete the item in the table at the specified index
--- If index is not specified, the last item will be removed and returned
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#deli)
--- @param table table
--- @param index? integer
--- @return any | nil
function pt.deli(table, index)
	return deli(table, index)
end
function pt.pop(table)
	return deli(table)
end

--- Get the length of a table
--- When value is specified, get the number of times value is in the table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#count)
--- @param table table
--- @param value? any
function pt.count(table, value) 
	count(table, value)
end

--- Returns an iterator for array like tables
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#all)
--- @param table table
--- @return function
function pt.all(table)
	return all(table)
end

--- For each item in the table, call function with each item as a parameter
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#foreach)
--- @param table table
--- @param func function
function pt.foreach(table, func) 
	foreach(table, func)
end

-- pairs and ipairs are builtin to lua, so there's no need to specify them here

--- Alias for table.pack
--- @param ... any
function pt.pack(...)  
	pack(...)
end

--- Alias for table.unpack
--- @param tbl table
--- @return any ...
function pt.unpack(tbl)
	return unpack(tbl)
end
--- @meta

--- /system/lib/undo.lua
--- @return __Undo
-- function create_undo_stack(save_state, load_state, pod_flags, item) end

--- @class __Undo
-- UNDO = {}

-- function UNDO:reset() end

-- function UNDO:undo() end

-- function UNDO:redo() end

-- function UNDO:checkpoint() end

-- function UNDO:new(save_state, load_state, pod_flags, item) end
--- @meta

--- @class userdata
--- @field x number
--- @field y number
--- @field z number
--- @operator add(userdata|number)
--- @operator sub(userdata|number)
--- @operator mul(userdata|number)
--- @operator div(userdata|number)
-- global record Userdata
-- 	x: number
-- 	y: number
-- 	z: number
-- 	width: function(self)
-- 	height: function(self)
-- 	get: function(self, integer, integer)
-- 	set: function(self, integer, ...: integer)
-- 	sort: function(self)
-- end


-- global enum userdata_type
-- 	"u8"
-- 	"i16"
-- 	"i32"
-- 	"i64"
-- 	"f64"
-- end

--- Creates a userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata)
--- @param data_type userdata_type The primitive type of the userdata's numbers
--- @param width integer
--- @param height integer
--- @param data? string string of hex values encoding the data or comma separated list of floats
--- @return userdata
--- @overload fun(data_type: userdata_type, width: integer, data: string?)
--- @overload fun(data: string)
function pt.userdata(data_type, width, height, data)
	return userdata(data_type, width, height, data)
end

--- Creates a vector (f64, 1d userdata)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#vec)
--- @return userdata
--- @param ... number
function pt.vec(...)
	return vec(...)
end

--- @class userdata
--- @return number
--- Get the magnitude of the vector
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global Userdata:magnitude = function(self)

--- @class userdata
--- @param v userdata
--- @return number
--- Get the distance to another vector
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:distance: any(v) 

--- @class userdata
--- @param v userdata
--- @return number
--- Get the dot product of another vector
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:dot: any(v) 

--- @class userdata
--- @param v userdata
--- @param v_out userdata | boolean
--- @return userdata
--- Get the cross product of another vector
--- If v_out is provided, the output will be stored in v_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Vector_methods)
-- global userdata: function:cross: any(v, v_out) 

--- @class userdata
--- @return integer
--- Gets the width of the userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_width)
-- global userdata: function:width: any() 

--- @class userdata
--- @return integer | nil
--- Gets the height of the userdata
--- Returns nil for a 1d userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_height)
-- global userdata: function:height: any() 

--- @class userdata
--- @return integer width
--- @return integer height
--- @return string type
--- @return integer dimensionality
--- Returns the attributes of the userdata
--- If the userdata is 1d, height will be 1
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_attribs)
-- global userdata: function:attribs: any() 

--- Gets values from a userdata as a multiple value return. If no index and no count are specified,
--- it will return all values in flat-indexed order.
--- If only an index is specified, it will return the value at that index. If the starting index
--- is out of range, it will return a single 0. If not, any additional values that are not in range will each be returned as 0.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
--- @param u userdata
--- @param x integer The x index to start from
--- @param y integer The y index to start from
--- @param n integer The number of flat-indexed values to get
--- @return number ... Each value from the starting index in flat-indexed order
--- @overload fun(u: userdata, x: integer, n: integer)
--- @overload fun(u: userdata, x: integer, y: integer)
--- @overload fun(u: userdata, x: integer)
--- @overload fun(u: userdata)
-- global get: function(u: any, x: any, y: any, n: any) 

-- userdata.get = get

--- @class userdata
--- @param x integer
--- @param ... number
--- Set one or more values starting at x
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
-- global userdata: function:set: any(x, ...) 

--- @class userdata
--- @param x integer
--- @param y integer
--- @param ... number
--- Set one or more values starting at x, y
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
-- global userdata: function:set: any(x, y, ...) 

--- Set one or more values starting at x
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
--- @param u userdata
--- @param x integer
--- @param ... number
-- global set: function(u: any, x: any, ...: any) 

--- Set one or more values starting at x, y
--- Out of range values have no effect
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_get)
--- @param u userdata
--- @param x integer
--- @param y integer
--- @param ... number
-- global set: function(u: any, x: any, y: any, ...: any) 

--- Copy a region of one userdata to another
--- Both src and dest must be the same type.
--- src and dest default to the current draw target.
--- width and height default to the src width and height.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#blit)
--- @param src? userdata
--- @param dest? userdata
--- @param src_x? integer
--- @param src_y? integer
--- @param dest_x? integer
--- @param dest_y? integer
--- @param width? integer
--- @param height? integer
-- global blit: function(src: any, dest: any, src_x: any, src_y: any, dest_x: any, dest_y: any, width: any, height: any) 

--- Get a row of a 2d userdata
--- Rows are 0-indexed
--- Returns nil if out of range
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_row)
--- @class userdata
--- @param i integer
--- @return userdata | nil
-- global userdata: function:row: any(i) 

--- Get a column of a 2d userdata
--- Columns are 0-indexed
--- Returns nil if out of range
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_row)
--- @class userdata
--- @param i integer
--- @return userdata | nil
-- global userdata: function:column: any(i) 

-- TODO userdata op functions
-- function userdata_op(u0, u1, u2, offset1, offset2, len, stride1, stride2, spans) end

--- @class userdata
--- @param m userdata
--- @param m_out? userdata | boolean
--- @return userdata | nil
--- Multiply two matrices together
--- If m_out is provided, the output will be stored in m_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul)
-- global userdata: function:matmul: any(m, m_out) 

-- This function is included in the manual, but is not real
-- --- Multiply two matrices together
-- --- If m_out is provided, the output will be stored in m_out, or in self if true
-- --- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul)
-- --- @param m0 userdata
-- --- @param m1 userdata
-- --- @param m_out? userdata | boolean
-- --- @return userdata | nil
-- function matmul(m0, m1, m_out) end

--- @class userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Matrix_methods)
-- global userdata: function:matmul2d: any(m, m_out) 

--- Multiply 3d 4x4 transformation matrices
--- If m_out is provided, the output will be stored in m_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul3d)
--- @param m userdata
--- @param m_out? userdata | boolean
-- global userdata: function:matmul3d: any(m, m_out) 

-- This function is included in the manual, but is not real
-- --- Multiply 3d 4x4 transformation matrices
-- --- If m_out is provided, the output will be stored in m_out, or in self if true
-- --- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#matmul3d)
-- --- @param m0 userdata
-- --- @param m1 userdata
-- --- @param m_out? userdata | boolean
-- --- @class userdata
-- function matmul3d(m0, m1, m_out) end

--- @class userdata
--- @param m_out? userdata | boolean
--- @return userdata
--- Transpose the matrix
--- If m_out is provided, the output will be stored in m_out, or in self if true
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Matrix_methods)
-- global userdata: function:transpose: any(m_out) 

--- Map the contents of an integer-type userdata to RAM
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memmap)
--- @param ud userdata
--- @param addr integer
-- global memmap: function(ud: any, addr: any) 

--- Unmap userdata from RAM
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#unmap)
--- @param ud userdata
--- @param addr? integer
-- global unmap: function(ud: any, addr: any) 

--- @class userdata
--- @param addr integer Address to read from
--- @param offset? integer Offset into userdata
--- @param elements? integer Number of elements to peek
--- @return integer ...
--- Read from RAM into an integer typed userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_peek)
-- global userdata: function:peek: any(addr, offset, elements) 

--- @class userdata
--- @param addr integer Address to write to
--- @param offset? integer Offset into userdata
--- @param elements? integer Number of elements to poke
--- Write to RAM from an integer typed userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_poke)
-- global userdata: function:poke: any(addr, offset, elements) 

--- Copy a region of one userdata to another
--- Both src and dest must be the same type.
--- dest defaults to the current draw target.
--- width and height default to the src width and height.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_blit)
--- @param dest? userdata
--- @param src_x? integer
--- @param src_y? integer
--- @param dest_x? integer
--- @param dest_y? integer
--- @param width? integer
--- @param height? integer
-- global userdata: function:blit: any(dest, src_x, src_y, dest_x, dest_y, width, height) 

--- Change the type or size of a userdata. Only integer types can be used.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_mutate)
--- @param data_type string u8, i16, i32, i64
--- @param width? integer
--- @param height? integer
-- global userdata: function:mutate: any(data_type, width, height) 

--- Linearly interpolate between two elements of a userdata
--- offset is the flat index to start from
--- len is the length (x1 - x0) of the lerp including the end (but not the start) element
--- el_stride is the distance between the elements
--- Multiple lerps can be performed at once using num_lerps and lerp_stride
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_lerp)
--- @param offset? integer
--- @param len? integer
--- @param el_stride? integer
--- @param num_lerps? integer
--- @param lerp_stride? integer
-- global userdata: function:lerp: any(offset, len, el_stride, num_lerps, lerp_stride) 

--- Return a copy of userdata cast as a different type.
--- When converting to ints, f64 values are floored and out of range values overflow
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_convert)
--- @param data_type string u8, i16, i32, i64, f64
--- @param dest? userdata
--- @return userdata
-- global userdata: function:convert: any(data_type, dest) 

-- global userdata: function:pow: any() 

-- global userdata: function:sgn: any() 

-- global userdata: function:sgn0: any() 

-- global userdata: function:abs: any() 

--- Sort a 2d userdata of any type by the value found at the index column (0 by default)
--- When descending is true, sort from largest to smallest
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_sort)
--- @param index? integer
--- @param descending? boolean
-- global userdata: function:sort: any(index, descending) 

-- === Userdata Operations ===

--- Applies add to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:add: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies sub to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:sub: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies mul to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:mul: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies div to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:div: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies integer division to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:idiv: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies mod to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:mod: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies band to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:band: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies bor to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:bor: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Applies bxor to each element and written to a new userdata
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:bxor: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Shifts the bits of each element to the left by n bits
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:shl: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Shifts the bits of each element to the right by n bits
--- If dest is userdata, result will be written to dest. If dest is true, result will be written to self
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_op)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:shr: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Copy the userdata
--- When :copy is given a table as the first argument (after self), it is taken to be a
--- lookup table into that userdata for the start of each span.
--- ** this form will be deprecated in 0.1.2 -- use :take instead with the same parameters.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_copy)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:copy: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Take values from the userdata at locations specified by idx.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#userdata_take)
--- @param idx userdata
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param idx_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:take: any(idx, dest, src_offset, dest_offset, len, idx_stride, dest_stride, spans) 

--- Returns the largest of each element or scalar
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#UserData_Operations)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:max: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 

--- Returns the smallest of each element or scalar
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#UserData_Operations)
--- @param src? userdata | number
--- @param dest? userdata | boolean
--- @param src_offset? integer
--- @param dest_offset? integer
--- @param len? integer
--- @param src_stride? integer
--- @param dest_stride? integer
--- @param spans? integer
--- @return userdata
-- global userdata: function:min: any(src, dest, src_offset, dest_offset, len, src_stride, dest_stride, spans) 
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
-- global record __WindowAttribs
-- 	autoclose: boolean
-- 	cursor: integer | string | Userdata
-- 	fullscreen: boolean
-- 	has_frame: boolean
-- 	height: integer
-- 	immortal: boolean
-- 	moveable: boolean
-- 	pausable: boolean
-- 	pwc_output: boolean
-- 	resizable: boolean
-- 	show_in_workspace: boolean
-- 	tabbed: boolean
-- 	title: string
-- 	video_mode: integer
-- 	wallpaper: boolean
-- 	width: integer
-- 	x: integer
-- 	y: integer
-- 	z: integer
-- end

--- Get the current display as a u8, 2d userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#get_display)
--- @return userdata
function pt.get_display()
	return get_display()
end

--- Set the draw target to a u8, 2d userdata
--- If ud is not provided, set the draw target to the current display
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#set_draw_target)
--- @param ud? userdata
function pt.set_draw_target(ud) 
	set_draw_target(ud)
end

--- Gets the current draw target as a u8, 2d userdata
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#get_draw_target)
--- @return userdata
function pt.get_draw_target()
	return get_draw_target()
end

--- Create a window or set its attributes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#window)
--- @param width integer
--- @param height integer
--- @param attribs? __WindowAttribs
function pt.set_window_size(attribs) 
	window(attribs)
end
function pt.set_window_attributes(width, height, attribs) 
	window(width, height, attribs)
end

--- Create a window or set its attributes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#window)
--- @param attribs? __WindowAttribs
-- global window: function(attribs: __WindowAttribs) 
--- @meta

--- Manage working with a file
--- save_state is a function that returns the content and metadata of the file to save. Called when the "save_file" event is fired
--- load_state is a function that takes the content and metadata of the file as parameters. Called when the "open_file" event is fired
--- untitled filename is the file name to use by default
--- get_hlocation is a function that gets the location in the file
--- set_hlocation is a function that sets the location in the file
--- View implementation in /system/lib/wrangle.lua
--- @param save_state? function
--- @param load_state? function
--- @param untitled_filename? string
--- @param get_hlocation? function
--- @param set_hlocation? function
function pt.wrangle_working_file(save_state, load_state, untitled_filename, get_hlocation, set_hlocation) 
	wrangle_working_file(save_state, load_state, untitled_filename, get_hlocation, set_hlocation)
end

--- Gets the present working file. Used with wrangle_working_file
--- View implementation in /system/lib/wrangle.lua
--- @return string | nil
function pt.pwf()
	return pwf()
end

return pt
