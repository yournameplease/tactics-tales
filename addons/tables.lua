--- @meta

--- Add an element to a table
--- If index is not specified, the item will be added to the end of the table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#add)
--- @param table table
--- @param value any
--- @param index? number
function add(table, value, index) end

--- Delete the first instance of value in table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#del)
--- @param table table
--- @param value any
--- @return any | nil
function del(table, value) end

--- Delete the item in the table at the specified index
--- If index is not specified, the last item will be removed and returned
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#deli)
--- @param table table
--- @param index? integer
--- @return any | nil
function deli(table, index) end

--- Get the length of a table
--- When value is specified, get the number of times value is in the table
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#count)
--- @param table table
--- @param value? any
function count(table, value) end

--- Returns an iterator for array like tables
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#all)
--- @param table table
--- @return function
function all(table) end

--- For each item in the table, call function with each item as a parameter
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#foreach)
--- @param table table
--- @param func function
function foreach(table, func) end

-- pairs and ipairs are builtin to lua, so there's no need to specify them here

--- Alias for table.pack
--- @param ... any
function pack(...) end

--- Alias for table.unpack
--- @param tbl table
--- @return any ...
function unpack(tbl) end
