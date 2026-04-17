--- @meta

--- Returns the minimum of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MIN)
--- @param x number
--- @param y number
--- @return number
function min(x, y) end

--- Returns the maximum of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MAX)
--- @param x number
--- @param y number
--- @return number
function max(x, y) end

--- Returns the middle value of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MID)
--- @param x number
--- @param y number
--- @param z number
--- @return number
function mid(x, y, z) end

--- Returns the nearest integer at or below a number
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#FLR)
--- @param x number
--- @return integer
function flr(x) end

--- Returns the nearest integer at or above a number
--- [View Online](https://pico-8.fandom.com/wiki/Ceil)
--- @param val number
--- @return integer
function ceil(val) end

--- Generate a random number under the given limit
--- or a random element from the table
--- Limit is 1 if not set
--- [View Online](https://pico-8.fandom.com/wiki/Rnd)
--- @param limit? number
--- @return number
function rnd(limit) end

--- Generate a random number under the given limit
--- or a random element from the table
--- [View Online](https://pico-8.fandom.com/wiki/Rnd)
--- @param tbl table
--- @return any
function rnd(tbl) end

--- Initializes the random number generator with an explicit seed value
--- [View Online](https://pico-8.fandom.com/wiki/Srand)
--- @param val number
function srand(val) end

--- Converts a value to a number
--- @param val any
--- @param format_flags? integer
--- @return number
function tonum(val, format_flags) end

--- Returns the absolute value of a number
--- [View Online](https://pico-8.fandom.com/wiki/Abs)
--- @param n number
--- @return number
function abs(n) end

--- Returns the sign of a number. 1 for positive, -1 for negative
--- [View Online](https://pico-8.fandom.com/wiki/Sgn)
--- @param n number
--- @return -1 | 1
function sgn(n) end

--- Calculates the arctangent of dx/dy formed by the vector on the unit circle.
--- The result is adjusted to represent the full circle.
--- [View Online](https://pico-8.fandom.com/wiki/Atan2)
function atan2(dx, dy) end

--- Calculates the sin of an angle
--- Uses a range of 0.0 to 1.0 to represent the angle. Sometimes called turns.
--- Example: 180 degrees or pi radians is 0.5 turns.
--- [View Online](https://pico-8.fandom.com/wiki/Sin)
--- @param angle number
--- @return number
function sin(angle) end

--- Calculates the sin of an angle
--- Uses a range of 0.0 to 1.0 to represent the angle. Sometimes called turns.
--- Example: 180 degrees or pi radians is .5 turns.
--- [View Online](https://pico-8.fandom.com/wiki/Cos)
--- @param angle number
--- @return number
function cos(angle) end

--- Calculates the square root of a number
--- [View Online](https://pico-8.fandom.com/wiki/Sqrt)
--- @param n number
--- @return number
function sqrt(n) end
