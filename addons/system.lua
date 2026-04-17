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
local __Environment = {}

-- Defining _ENV causes these definitions in system.lua to be ignored
-- @type any
-- _ENV = {}

--- Gets the environment variables given to the process at its creation
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#env)
--- @return __Environment
function env() end

--- Exits the program
--- @param exit_code? integer
function exit(exit_code) end

--- Prints text to the host system's console
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#printh)
--- @param value any
function printh(value) end

--- @param filename string
--- @param env? __Environment
function create_process(filename, env) end

--- Stop the cart and optionally print a message
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#stop)
--- @param message? string
function stop(message) end

--- If condition is false, stop the cart and print a message
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#assert)
--- @param condition boolean
--- @param message? string
function assert(condition, message) end

--- Get the number of seconds elapsed since the cartridge was run
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#time)
--- @return number
function time() end

--- Get the number of seconds elapsed since the cartridge was run
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#t)
--- @return number
function t() end

--- Get the current date and time formatted using Lua's standard date strings
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#date)
--- @param format? string
--- @param t? integer | string
--- @param delta? number
--- @return string
function date(format, t, delta) end

--- Set the system clipboard
--- @param text string
function set_clipboard(text) end

--- Get the system clipboard
--- @return string
function get_clipboard() end

--- Adds an event listener
--- @param event string
--- @param callback function
function on_event(event, callback) end

--- Sends an event to a process
--- @param pid integer
--- @param event table
function send_message(pid, event) end

--- Get the current process id
--- @return integer
function pid() end

--- Create a notification toast
--- @param message string
function notify(message) end

-- should stat(n) return any? i think it always returns a number, but that might not always be true

--- Returns information about the current runtime environment
--- If addr is specified, copy the result to addr. This isn't fully documented, see [Querying Mixer State](https://pico-8.fandom.com/wiki/Stat?fandom=allow)
--- [View Online](https://pico-8.fandom.com/wiki/Stat)
--- @param id integer
--- @param addr? integer
--- @return any
function stat(id, addr) end

--- Get a property from the current theme (/ram/shared/theme.pod)
--- @param which string
--- @return any
function theme(which) end

--- Opens a file using the system file associations (/system/util/open.lua)
--- @param file string
function open(file) end
