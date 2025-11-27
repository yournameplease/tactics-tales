--- @meta

--- Add an element to a table
--- If index is not specified, the item will be added to the end of the table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#add)
--- @param table table
--- @param value any
--- @param index? number
global add: function(table: any, value: any, index: number) 

--- Delete the first instance of value in table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#del)
--- @param table table
--- @param value any
--- @return any | nil
global del: function(table: any, value: any) : any | nil

--- Delete the item in the table at the specified index
--- If index is not specified, the last item will be removed and returned
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#deli)
--- @param table table
--- @param index? integer
--- @return any | nil
global deli: function(table: any, index: any) : any | nil

--- Get the length of a table
--- When value is specified, get the number of times value is in the table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#count)
--- @param table table
--- @param value? any
global count: function(table: any, value: any) 

--- Returns an iterator for array like tables
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#all)
--- @param table table
--- @return function
global all: function(table: any) : any

--- For each item in the table, call function with each item as a parameter
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#foreach)
--- @param table table
--- @param func function
global foreach: function(table: any, func: any) 

-- pairs and ipairs are builtin to lua, so there's no need to specify them here

--- Alias for table.pack
--- @param ... any
global pack: function(...: any)  

--- Alias for table.unpack
--- @param tbl table
--- @return any ...
global unpack: function(tbl: any) : any
