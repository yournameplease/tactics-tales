--- @meta

--- @class __FileMetadata
--- @field created string
--- @field modified string
--- @field pod_format? string
--- @field revision? integer
__FileMetadata = {}

--- Change the current working directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cd)
--- @param path string
function cd(path) end

--- Gets the file type, size, and origin
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fstat)
--- @param path string
--- @return string | nil type
--- @return number | nil size
--- @return string | nil origin
function fstat(path) end

--- Converts a relative path to an absolute path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fullpath)
--- @param filename string
--- @return string
function fullpath(filename) end

--- Lists the contents of a folder
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ls)
--- @param path? string
--- @return string[]
function ls(path) end

--- Copy a file from src to dest. Folders are copied recursively and the dest is overwritten.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cp)
--- @param src string
--- @param dest string
function cp(src, dest) end

--- Move a file from src to dest. Folders are copied recursively and the dest is overwritten.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mv)
--- @param src string
--- @param dest string
function mv(src, dest) end

--- Delete a file or folder (recursive)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#rm)
--- @param filename string
function rm(filename) end

--- Return the present working directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pwd)
--- @return string
function pwd() end

--- Read a lua object from a file
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fetch)
--- @param filename string
--- @return any
--- @return __FileMetadata?
function fetch(filename) end

--- Store a lua object to a file
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#store)
--- @param filename string
--- @param object table | string | userdata | boolean | number
--- @param metadata? __FileMetadata
function store(filename, object, metadata) end

--- Fetch just the metadata of a path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fetch_metadata)
--- @param filename string
--- @return __FileMetadata | nil
function fetch_metadata(filename) end

--- Store just the metadata of a path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#store_metadata)
--- @param filename string
--- @param metadata __FileMetadata
function store_metadata(filename, metadata) end

--- Create a directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mkdir)
--- @param name string
function mkdir(name) end

-- --- @param filename string
-- function include(filename)
--     require(filename)
-- end

--- Mounts a folder. Creates a link from origin to target
--- View implementation in /system/lib/fs.lua
--- @param target string
--- @param origin string
function mount(target, origin) end

--- Loads and runs a lua file like a function.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#include)
--- @param filename string The path to the file relative to the working directory. Must include the file extension.
--- @return any? #The return value of the file, if any.
function include(filename) end