require("src/tactics/ui/box")
require("src/tactics/systems/event_bus")
require("src/tactics/ui/components/text_node")
require("src/tactics/util/text")
require("src/tactics/ui/components/message_log")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/story/story_context")
local lists = require("src/tactics/util/lists")

global record EventMessageLog
    is UIElement, TextUIElement
end
 
function EventMessageLog.new(props: MessageLog): EventMessageLog
    props.func = function(state: UIContextManager, row_limit: integer): { string }
        return lists.map(
            function(e: GameEvent): string return "> "..e  end
        )(state.game_context.event_bus:get_event_history(row_limit))
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.wrap = props.draw_properties.wrap or "ellipsis"
    props.draw_properties.direction = props.draw_properties.direction or 'up'
    return MessageLog.new(props) as EventMessageLog
end

return EventMessageLog
