local CONFIG = require("src/config")

local Log = {}

local log_level = CONFIG.LOG_LEVEL

local function should_print (level: LogLevel): boolean
    if log_level == "ERROR" then
        return level == "ERROR"
    elseif log_level == "WARN" then
        return level == "WARN" or level == "ERROR"
    elseif log_level == "INFO" then
        return level == "INFO" or level == "WARN" or level == "ERROR"
    elseif log_level == "DEBUG" then
       return level ~= "TRACE"
    elseif log_level == "TRACE" then
       return true
    end
end


local function debug_print(level: LogLevel, ...: any)
    if should_print(level) then
        local array = {...}
        local str = ""
        for i=1,#array-1 do
            local v = array[i]
            if type(v) == "boolean" then
                v = v and "TRUE" or "FALSE"
            end
            if v is string then
                str = str .. v .. " , "
            else
                error("Logging undefined type!")
            end
        end
        local v = array[#arg]
        if type(v) == "boolean" then
            v = v and "TRUE" or "FALSE"
        end

        if v is string then
            str = str .. v
        else
            error("Logging undefined type!")
        end

        printh(level .. ": " .. str)
    end
end

function Log.error(...: any)
    debug_print("ERROR", ...)
end

function Log.warn(...: any)
    debug_print("WARN", ...)
end

function Log.info(...: any)
    debug_print("INFO", ...)
end

function Log.debug(...: any)
    debug_print("DEBUG", ...)
end

function Log.trace(...: any)
    debug_print("TRACE", ...)
end

return Log
