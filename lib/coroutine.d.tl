--- @meta

--- Create a coroutine for a function
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#COCREATE)
--- @param func function
--- @return thread
global cocreate: function(func: any) 

--- Run or continue the coroutine c. Parameters are passed to the function
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#CORESUME)
--- @param c thread
--- @param ... any
--- @return boolean error
--- @return ... any
global coresume: function(c: any, ...: any) 

--- Checks the status of a coroutine
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#COSTATUS)
--- @param c thread
--- @return string
global costatus: function(c: any) 

--- Yield the coroutine back to the caller
--- [View Online](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#YIELD)
--- @param ... any
global yield: function(...: any) 
