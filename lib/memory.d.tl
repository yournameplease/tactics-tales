--- @meta

--- Read a byte from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek)
--- @param addr integer
--- @param n? integer
--- @return integer ...
global peek: function(addr: integer, n: integer): integer

--- Read an i16 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek2)
--- @param addr integer
--- @param n? integer
--- @return integer ...
global peek2: function(addr: integer, n: integer): integer

--- Read an i32 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek4)
--- @param addr integer
--- @param n? integer
--- @return integer ...
global peek4: function(addr: integer, n: integer): integer

--- Read an i64 from an address in memory
--- If n is provided, return that number of results
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#peek4)
--- @param addr integer
--- @param n? integer
--- @return integer ...
global peek8: function(addr: integer, n: integer): integer

--- Write a byte to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke)
--- @param addr integer
--- @param ... integer
global poke: function(addr: integer, ...: {integer})

--- Write an i16 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke2)
--- @param addr integer
--- @param ... integer
global poke2: function(addr: integer, ...: integer)

--- Write an i32 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke4)
--- @param addr integer
--- @param ... integer
global poke4: function(addr: integer, ...: integer)

--- Write an i64 to an address in memory
--- If multiple values are given, they will be written sequentially
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#poke4)
--- @param addr integer
--- @param ... integer
global poke8: function(addr: integer, ...: integer)

--- Copy len bytes from source address to destination address
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memcpy)
--- @param dest_addr integer
--- @param source_addr integer
--- @param len integer
global memcpy: function(dest_addr: integer, source_addr: integer, len: integer) 

--- Write the byte val to destination address for len bytes
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#memset)
--- @param dest_addr integer
--- @param val integer
--- @param len integer
global memset: function(dest_addr: integer, val: integer, len: integer) 
