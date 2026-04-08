---@meta

--- Called after main.lua is run, but before the first call to `_update`.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Program_Stucture)
function _init() end

--- Called 60 times per second, provided that the `_update` function does not exceed ~90% CPU
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Program_Stucture)
function _update() end

--- Called each time the window manager asks for a frame.
--- If `_update` and `_draw` combined exceed ~90% CPU, draw will be called less frequently.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Program_Stucture)
function _draw() end
