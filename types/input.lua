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
function btn(button, player) end

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
function btnp(button, player) end

--- Get the state of a key
--- If raw is set, ignore the keyboard layout
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#key)
--- @param k string
--- @param raw? boolean
--- @return boolean
function key(k, raw) end

--- Get the state of a key held down
--- If raw is set, ignore the keyboard layout
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#keyp)
--- @param k string
--- @param raw? boolean
--- @return boolean
function keyp(k, raw) end

--- Reset the state of a key until the end of frame
--- View implementation in /system/lib/events.lua
--- @param k string
function clear_key(k) end

--- Check if text is waiting to be read with `readtext()`
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peektext)
--- @return boolean
function peektext() end

--- Read the next peice of text waiting
--- If clear is set, discard remaining text
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#readtext)
--- @param clear? boolean
function readtext(clear) end

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
function mouse(new_mx, new_my) end

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
function mouselock(lock, event_sensitivity, move_sensitivity) end

--- Allows terminal programs to be interactive
--- Execution of the program is blocked until the user enters a response,
--- and that response is returned
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#input)
--- @param prompt string
--- @param flags? 0x1 | 0x2 | 0x4
function input(prompt, flags) end