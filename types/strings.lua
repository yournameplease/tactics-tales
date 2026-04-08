--- @meta

--- @class string
string = {}

--- Get the extension of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
function string:ext() end

--- Get the basename (filename and extension) of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
function string:basename() end

--- Get the path of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
function string:path() end

--- Get the hloc(?) of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
function string:hloc() end

--- Get the directory of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
function string:dirname() end

--- Get the protocol (e.g. http) of a file
--- Assumes string is a path
--- View implementation in /system/lib/head.lua
--- @return string
function string:prot() end

--- Converts 1 or more ordinal character codes to a string
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#chr)
--- @param val integer
--- @param ... integer
function chr(val, ...) end

--- Convert 1 or more characters from a string to ordinal character codes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ord)
--- @param str string
--- @param index? integer
--- @param num_results? integer
--- @return (integer | nil) ...
function ord(str, index, num_results) end

--- Get the substring from pos0 to pos1 (inclusive)
--- If pos1 is not specified, return substring from pos0 to end of string
--- If pos1 is not a number, return a single character at pos0
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#sub)
--- @param str string
--- @param pos0 integer
--- @param pos1? integer | boolean
--- @return string
function sub(str, pos0, pos1) end

--- Converts a value to a string.
--- @param value any The value to convert.
--- @param as_hex? boolean If true, numbers will be converted to a hexidecimal string. Non-numbers will convert to 0x0. Decimal numbers will error.
--- @return string The string representation of the value.
function tostr(value, as_hex) end

--- Splits a string on a separator
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#split)
--- @param str string
--- @param separator? string
--- @param convert_numbers? true
--- @return number[]
function split(str, separator, convert_numbers) end

--- Splits a string on a separator
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#split)
--- @param str string
--- @param separator? string
--- @param convert_numbers? false
--- @return string[]
function split(str, separator, convert_numbers) end
string.split = split

--- Create a string encoding all the information needed to get from str0 to str1.
--- The delta can be used with apply_delta to produce str1 given only str0.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#create_delta)
--- @param str0 string
--- @param str1 string
--- @return string
function create_delta(str0, str1) end

--- Apply a delta created with create_delta to str0. This will produce str1.
--- str0 must be the exactly the same as the string used to create the delta; otherwise apply_delta returns nil.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#apply_delta)
--- @param str0 string
--- @param delta string
--- @return string | nil
function apply_delta(str0, delta) end
