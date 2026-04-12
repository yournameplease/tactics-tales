---@brief
--- Contains a simple logging utility for printing debug messages
--- based on log levels.

---@param level LogLevel
---@return boolean
local function should_print(level)
    local log_level = DYNAMIC_CONFIG.log_level
    if log_level == "NONE" then
        return false
    elseif log_level == "ERROR" then
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
    return false
end

---@param level LogLevel
---@param ... any
local function debug_print(level, ...)
    if should_print(level) then
        local array = {...}
        local str = ""
        for i = 1, #array - 1 do
            local v = array[i]
            if type(v) == "boolean" then
                v = v and "TRUE" or "FALSE"
            end
            if type(v) == "string" then
                str = str .. v .. " , "
            elseif v == nil then
                str = str .. "<nil> , "
            else
                str = str .. tostring(v) .. " , "
            end
        end
        local v = array[#array]
        if type(v) == "boolean" then
            v = v and "TRUE" or "FALSE"
        end

        if type(v) == "string" then
            str = str .. v
        elseif v == nil then
            str = str .. "<nil> , "
        else
            str = str .. tostring(v)
        end

        printh(level .. ": " .. str)
    end
end

log = {
    error = function(...)
        debug_print("ERROR", ...)
    end,
    warn = function(...)
        debug_print("WARN", ...)
    end,
    info = function(...)
        debug_print("INFO", ...)
    end,
    debug = function(...)
        debug_print("DEBUG", ...)
    end,
    trace = function(...)
        debug_print("TRACE", ...)
    end,
}
