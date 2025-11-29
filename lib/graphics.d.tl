--- @meta

--- Changes the video mode
--- 0 is 480x720
--- 3 is 240x135
--- 4 is 160x90
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#vid)
--- @param mode 0 | 3 | 4
global vid: function(mode: integer) 

--- Clears the screen and resets the clipping rectangle
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cls)
--- @param col? integer
global cls: function(col?: integer) 

--- Prints text on screen
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#print)
--- @param value any The object to print.
--- @param x? integer The x coordinate to print at.
--- @param y? integer The y coordinate to print at.
--- @param col? integer The color index to print in.
--- @return integer new_x The x coordinate of the next character to be printed.
--- @return integer new_y The y coordinate of the next character to be printed.
-- global print: function(value: integer, x: integer, y: integer, col: integer): integer, integer

--- Sets the clipping rectangle for drawing operations.
--- If clip_previous is set, the new region will be clipped by the old region
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#clip)
--- @param x integer
--- @param y integer
--- @param w integer
--- @param h integer
--- @param clip_previous? boolean
global clip: function(x: integer, y: integer, w: integer, h: integer, clip_previous?: boolean) 

--- Reset clipping region
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#clip)
--- @return integer x
--- @return integer y
--- @return integer w
--- @return integer h
-- global clip: function(): integer, integer, integer, integer 

--- Sets the pixel to at x, y to the color index 0 to 63
--- If color is not specified, uses the current draw color instead
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pset)
--- @param x integer
--- @param y integer
--- @param col? integer
global pset: function(x: integer, y: integer, col?: integer) 

--- Returns the color of the pixel at x, y
--- Returns 0 if out of bounds
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pget)
--- @param x integer
--- @param y integer
--- @return integer
global pget: function(x: integer, y: integer) : integer

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
-- global fget: function(n: integer, f: integer) : boolean
global fget: function(n: integer) : integer

--- Set the value of a sprite n's flag f (0-7)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fset)
--- @param n integer
--- @param f integer
--- @param val boolean
global fset: function(n: integer, f: integer, val: boolean) 

--- Set the cursor position
--- If color is specified, also set the current color
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cursor)
--- @param x integer
--- @param y integer
--- @param col? integer
global cursor: function(x: integer, y: integer, col?: integer) 

--- Set the current color
--- If color is not specified, set the current color to 6
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#color)
--- @param col integer
global color: function(col?: integer) 

--- Set a screen offset of -x, -y for all drawing operations
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#camera)
--- @param x integer
--- @param y integer
--- @return integer x
--- @return integer y
global camera: function(x?: integer, y?: integer) : integer, integer

--- Reset the camera offset
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#camera)
--- @return integer x
--- @return integer y
-- global camera: function()

--- Draw a circle at x, y with radius r
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#circ)
--- @param x integer
--- @param y integer
--- @param r integer
--- @param col? integer
global circ: function(x: integer, y: integer, r: integer, col?: integer) 

--- Draw a filled circle at x, y with radius r
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#circfill)
--- @param x integer
--- @param y integer
--- @param r integer
--- @param col? integer
global circfill: function(x: integer, y: integer, r: integer, col?: integer) 

--- Draw an ellipse within the given rectangle
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#oval)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
global oval: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: integer) 

--- Draw a filled ellipse within the given rectangle
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ovalfill)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
global ovalfill: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: integer) 

--- Draw a line from (x0, y0) to (x1, y1)
--- If (x1, y1) are not given the end of the last line will be used
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#line)
--- @param x0 integer
--- @param y0 integer
--- @param x1? integer
--- @param y1? integer
--- @param col? integer
global line: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: integer) 

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
global rect: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: integer) 
global rrect: function(x: integer, y: integer, w: integer, h: integer, radius?: integer, col?: integer) 

--- Draw a filled rectangle within the given points
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#rectfill)
--- @param x0 integer
--- @param y0 integer
--- @param x1 integer
--- @param y1 integer
--- @param col? integer
global rectfill: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: integer) 
global rrectfill: function(x: integer, y: integer, w: integer, h: integer, radius?: integer, col?: integer) 

--- Remaps one color index to produce another.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pal)
--- @param c0 integer The index to remap.
--- @param c1 integer The index to map c0 to.
--- @param p? 0 | 1 0 to swap during drawing, 1 to swap the entire screen. Defaults to 0.
global pal: function(c0?: integer, c1?: integer, p?: integer) 

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
global palt: function(c?: integer, is_transparent?: boolean) 

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
global spr: function(s: integer, x?: number, y?: number, flip_x?: boolean, flip_y?: boolean) 

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
global sspr: function(s: integer, sx?: integer, sy?: integer, sw?: integer, sh?: integer, dx?: integer, dy?: integer, dw?: integer, dh?: integer, flip_x?: boolean, flip_y?: boolean) 

--- Set a 4x4 fill pattern using Pico-8 style fill patterns
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fillp)
--- @param p integer
--- @param ... integer
-- global fillp: function(p?: integer, ...: integer) 
global fillp: function(...: any) 

--- Get the sprite for a given index
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#get_spr)
--- @param index integer
--- @return userdata
global get_spr: function(index: integer) : Userdata

--- Set the sprite for a given index
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#set_spr)
--- @param index integer
--- @param ud userdata
global set_spr: function(index: integer, ud: Userdata) 

--- Copies the graphics buffer to the screen, then syncronizes to the next frame
--- [View Online](https://pico-8.fandom.com/wiki/Flip)
--- @param flags? integer
global flip: function(flags?: integer) 
