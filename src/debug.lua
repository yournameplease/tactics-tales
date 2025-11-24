
Log = {}

local log_level = CONFIG.LOG_LEVEL

function should_print (level)
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


local function debug_print(level, ...)
    if should_print(level) then
        local arg = {...}
        local str = ""
        for i=1,#arg-1 do
            str = str .. arg[i] .. " , "
        end
        str = str .. arg[#arg]

        printh(level .. ": " .. str)
    end
end

function Log.error(...)
    debug_print("ERROR", ...)
end

function Log.warn(...)
    debug_print("WARN", ...)
end

function Log.info(...)
    debug_print("INFO", ...)
end

function Log.debug(...)
    debug_print("DEBUG", ...)
end

function Log.trace(...)
    debug_print("TRACE", ...)
end

return Log