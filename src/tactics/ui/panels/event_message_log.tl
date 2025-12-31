local box = require("src/tactics/ui/box")
local event_bus = require("src/tactics/systems/event_bus")
local text_node = require("src/tactics/ui/components/text_node")
local message_log = require("src/tactics/ui/components/message_log")
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
local lists = require("src/tactics/util/lists")

local record EventMessageLog
    is box.UIElement, text_node.TextUIElement
end

local event_message_log = {}

function event_message_log.new(props: message_log.MessageLog): box.UIElement
    props.func = function(state: UIContextManager, row_limit: integer): { string }
        return lists.map(
            function(e: event_bus.GameEvent): string return "> "..e  end
        )(state.game_context.event_bus:get_event_history(row_limit))
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.wrap = props.draw_properties.wrap or "ellipsis"
    props.draw_properties.direction = props.draw_properties.direction or 'up'
    return message_log.new(props) as EventMessageLog
end

return event_message_log
