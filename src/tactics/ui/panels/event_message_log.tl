require("src/ui/box")
require("src/systems/event_bus")
require("src/ui/components/text_node")
require("src/ui/components/message_log")
require("src/ui/ui_context_manager")
require("src/story/story_context")
local maps = require("src/util/maps")

global record EventMessageLog
    is UIElement, TextUIElement
end
 
function EventMessageLog.new(props: MessageLog): EventMessageLog
    props.func = function(state: UIContextManager, _row_limit: integer): { string }
        return maps.map(state.story_context.ctx.services.event_bus:get_event_history(), function(e: GameEvent): string return "> "..e  end)
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.text_direction = props.draw_properties.text_direction or 'up'
    return MessageLog.new(props) as EventMessageLog
end

return EventMessageLog
