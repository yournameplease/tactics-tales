--- @meta

--- Environment Properties
--- @class __Environment
--- @field argv? string[]
--- @field immortal? boolean
--- @field parent_pid? integer
--- @field path? string
--- @field print_to_proc_id? integer
--- @field prog_name? string
--- @field title? string
--- @field window_attribs? __WindowAttribs
global record __Environment 
	argv: {string}
	immortal: boolean
	parent_pid: integer
	path: string
	print_to_proc_id: integer
	prog_name: string
	title: string
	window_attribs: __WindowAttribs
end




-- Defining _ENV causes these definitions in system.lua to be ignored
-- @type any
-- _ENV = {}

--- Gets the environment variables given to the process at its creation
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#env)
--- @return __Environment
global env: function() : __Environment 

--- Exits the program
--- @param exit_code? integer
global exit: function(exit_code: integer) 

--- Prints text to the host system's console
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#printh)
--- @param value any
global printh: function(value: any) 

--- @param filename string
--- @param env? __Environment
global create_process: function(filename: string, env: __Environment) 

--- Stop the cart and optionally print a message
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#stop)
--- @param message? string
global stop: function(message: string) 

--- If condition is false, stop the cart and print a message
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#assert)
--- @param condition boolean
--- @param message? string
-- global assert: function(condition: boolean, message: string) 

--- Get the number of seconds elapsed since the cartridge was run
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#time)
--- @return number
global time: function() : number

--- Get the number of seconds elapsed since the cartridge was run
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#t)
--- @return number
global t : function() : number

--- : anyGet the current date and time formatted using Lua's standard date 
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#date)
--- @param format? string
--- @param t? integer | string
--- @param delta? number
--- @return string
global date: function(format: string, t: integer | string, delta: number): string 

--- Set the system clipboard
--- @param text string
global set_clipboard: function(text: string) 

--- Get the system clipboard
--- @return string
global get_clipboard: function(): string 

--- Adds an event listener
--- @param event string
--- @param callback function
global on_event: function(event: string, callback: any) 

--- Sends an event to a process
--- @param pid integer
--- @param event table
global send_message: function(pid: integer, event: any) 

--- Get the current process id
--- @return integer
global pid: function() : integer 

--- Create a notification toast
--- @param message string
global notify: function(message: string) 

-- should stat(n) return any? i think it always returns a number, but that might not always be true

--- Returns information about the current runtime environment
--- If addr is specified, copy the result to addr. This isn't fully documented, see [Querying Mixer State](https://pico-8.fandom.com/wiki/Stat?fandom=allow)
--- [View Online](https://pico-8.fandom.com/wiki/Stat)
--- @param id integer
--- @param addr? integer
--- @return any
global stat: function(id: integer, addr: integer) 

--- Get a property from the current theme (/ram/shared/theme.pod)
--- @param which string
--- @return any
global theme: function(which: string) 

--- Opens a file using the system file associations (/system/util/open.lua)
--- @param file string
global open: function(file: string) 
