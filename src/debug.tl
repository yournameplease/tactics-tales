require("src/config")

global LOG = {}

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
                str = str .. v as string
                -- error("Logging undefined type!")
            end
        end
        local v = array[#array]
        if type(v) == "boolean" then
            v = v and "TRUE" or "FALSE"
        end

        if v is string then
            str = str .. v
        else
            str = str .. v as string
            -- printh("Warning: Logging undefined type "..type(v))
        end

        printh(level .. ": " .. str)
    end
end

function LOG.error(...: any)
    debug_print("ERROR", ...)
end

function LOG.warn(...: any)
    debug_print("WARN", ...)
end

function LOG.info(...: any)
    debug_print("INFO", ...)
end

function LOG.debug(...: any)
    debug_print("DEBUG", ...)
end

function LOG.trace(...: any)
    debug_print("TRACE", ...)
end

return LOG
