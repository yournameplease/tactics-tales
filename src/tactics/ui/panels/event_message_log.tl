require("src/tactics/ui/box")
require("src/tactics/systems/event_bus")
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/components/message_log")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/story/story_context")
local maps = require("src/tactics/util/maps")

global record EventMessageLog
    is UIElement, TextUIElement
end
 
function EventMessageLog.new(props: MessageLog): EventMessageLog
    props.func = function(state: UIContextManager, row_limit: integer): { string }
        return maps.map(state.game_context.event_bus:get_event_history(row_limit), function(e: GameEvent): string return "> "..e  end)
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.direction = props.draw_properties.direction or 'up'
    return MessageLog.new(props) as EventMessageLog
end

return EventMessageLog
