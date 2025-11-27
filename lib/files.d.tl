--- @meta

--- @class __FileMetadata
--- @field created string
--- @field modified string
--- @field pod_format? string
--- @field revision? integer
global record __FileMetadata
	created: string
	modified: string
	pod_format: string
	revision: integer
end

--- Change the current working directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cd)
--- @param path string
global cd: function(path: any) 

--- Gets the file type, size, and origin
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fstat)
--- @param path string
--- @return string | nil type
--- @return number | nil size
--- @return string | nil origin
global fstat: function(path: any): string, number, string 

--- Converts a relative path to an absolute path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fullpath)
--- @param filename string
--- @return string
global fullpath: function(filename: any) : string

--- Lists the contents of a folder
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#ls)
--- @param path? string
--- @return string[]
global ls: function(path: any) : {string}

--- Copy a file from src to dest. Folders are copied recursively and the dest is overwritten.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#cp)
--- @param src string
--- @param dest string
global cp: function(src: any, dest: any) 

--- Move a file from src to dest. Folders are copied recursively and the dest is overwritten.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mv)
--- @param src string
--- @param dest string
global mv: function(src: any, dest: any) 

--- Delete a file or folder (recursive)
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#rm)
--- @param filename string
global rm: function(filename: any) 

--- Return the present working directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pwd)
--- @return string
global pwd: function(): string

--- Read a lua object from a file
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fetch)
--- @param filename string
--- @return any
--- @return __FileMetadata?
global fetch: function(filename: any): any, __FileMetadata

--- Store a lua object to a file
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#store)
--- @param filename string
--- @param object table | string | userdata | boolean | number
--- @param metadata? __FileMetadata
global store: function(filename: string, object: any, metadata: __FileMetadata) 

--- Fetch just the metadata of a path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#fetch_metadata)
--- @param filename string
--- @return __FileMetadata | nil
global fetch_metadata: function(filename: string): __FileMetadata 

--- Store just the metadata of a path
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#store_metadata)
--- @param filename string
--- @param metadata __FileMetadata
global store_metadata: function(filename: any, metadata: __FileMetadata) 

--- Create a directory
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#mkdir)
--- @param name string
global mkdir: function(name: any) 

-- --- @param filename string
-- function include(filename)
--     require(filename)
-- end

--- Mounts a folder. Creates a link from origin to target
--- View implementation in /system/lib/fs.lua
--- @param target string
--- @param origin string
global mount: function(target: string, origin: string) 

--- Loads and runs a lua file like a function.
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#include)
--- @param filename string The path to the file relative to the working directory. Must include the file extension.
--- @return any? #The return value of the file, if any.
global include: function(filename: string) : any
