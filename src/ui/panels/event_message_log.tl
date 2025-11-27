Box = require("src/ui/box.lua")
MessageLog = require("src/ui/panels/message_log.lua")

local EventMessageLog = {}

function EventMessageLog.new(props)
    props.func = function(state, row_limit)
        return tmap(state.event_bus.get_event_history(), function(e) return "> "..e  end)
    end

    return MessageLog.new(props)
end

return EventMessageLog
