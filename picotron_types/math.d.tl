--- @meta

--- Returns the minimum of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MIN)
--- @param x number
--- @param y number
--- @return number
-- global min: function(x: number, y: number) : number
global min: function(x: integer, y: integer) : integer

--- Returns the maximum of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MAX)
--- @param x number
--- @param y number
--- @return number
-- global max: function(x: number, y: number) : number
global max: function(x: integer, y: integer) : integer

--- Returns the middle value of two numbers
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#MID)
--- @param x number
--- @param y number
--- @param z number
--- @return number
-- global mid: function(x: number, y: number, z: number) : number
global mid: function(x: integer, y: integer, z: integer) : integer

--- Returns the nearest integer at or below a number
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#FLR)
--- @param x number
--- @return integer
global flr: function(x: number) : integer

--- Returns the nearest integer at or above a number
--- [View Online](https://pico-8.fandom.com/wiki/Ceil)
--- @param val number
--- @return integer
global ceil: function(val: number) : integer

--- Generate a random number under the given limit
--- or a random element from the table
--- Limit is 1 if not set
--- [View Online](https://pico-8.fandom.com/wiki/Rnd)
--- @param limit? number
--- @return number
global rnd: function(limit: number) : number

--- Generate a random number under the given limit
--- or a random element from the table
--- [View Online](https://pico-8.fandom.com/wiki/Rnd)
--- @param tbl table
--- @return any
-- global rnd: function(tbl: number) : any

--- Initializes the random number generator with an explicit seed value
--- [View Online](https://pico-8.fandom.com/wiki/Srand)
--- @param val number
global srand: function(val: number) : number

--- Converts a value to a number
--- @param val any
--- @param format_flags? integer
--- @return number
global tonum: function(val: any, format_flags: integer) : number

--- Returns the absolute value of a number
--- [View Online](https://pico-8.fandom.com/wiki/Abs)
--- @param n number
--- @return number
-- global abs: function(n: number) : number
global abs: function(n: integer) : integer

--- Returns the sign of a number. 1 for positive, -1 for negative
--- [View Online](https://pico-8.fandom.com/wiki/Sgn)
--- @param n number
--- @return -1 | 1
global sgn: function(n: number) : integer

--- Calculates the arctangent of dx/dy formed by the vector on the unit circle.
--- The result is adjusted to represent the full circle.
--- [View Online](https://pico-8.fandom.com/wiki/Atan2)
global atan2: function(dx: number, dy: number) : number

--- Calculates the sin of an angle
--- Uses a range of 0.0 to 1.0 to represent the angle. Sometimes called turns.
--- Example: 180 degrees or pi radians is 0.5 turns.
--- [View Online](https://pico-8.fandom.com/wiki/Sin)
--- @param angle number
--- @return number
global sin: function(angle: number) : number

--- Calculates the sin of an angle
--- Uses a range of 0.0 to 1.0 to represent the angle. Sometimes called turns.
--- Example: 180 degrees or pi radians is .5 turns.
--- [View Online](https://pico-8.fandom.com/wiki/Cos)
--- @param angle number
--- @return number
global cos: function(angle: number) : number

--- Calculates the square root of a number
--- [View Online](https://pico-8.fandom.com/wiki/Sqrt)
--- @param n number
--- @return number
global sqrt: function(n: number) : number
