--- @meta

--- Read a byte from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function peek(addr, n) end

--- Read an i16 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek2)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function peek2(addr, n) end

--- Read an i32 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek4)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function peek4(addr, n) end

--- Read an i64 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek4)
--- @param addr integer
--- @param n? integer
--- @return integer ...
function peek8(addr, n) end

--- Write a byte to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke)
--- @param addr integer
--- @param ... integer
function poke(addr, ...) end

--- Write an i16 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke2)
--- @param addr integer
--- @param ... integer
function poke2(addr, ...) end

--- Write an i32 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke4)
--- @param addr integer
--- @param ... integer
function poke4(addr, ...) end

--- Write an i64 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke4)
--- @param addr integer
--- @param ... integer
function poke8(addr, ...) end

--- Copy len bytes from source address to destination address
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memcpy)
--- @param dest_addr integer
--- @param source_addr integer
--- @param len integer
function memcpy(dest_addr, source_addr, len) end

--- Write the byte val to destination address for len bytes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memset)
--- @param dest_addr integer
--- @param val integer
--- @param len integer
function memset(dest_addr, val, len) end
