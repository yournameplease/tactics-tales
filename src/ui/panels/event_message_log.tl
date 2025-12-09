require("src/ui/box")
require("src/systems/event_bus")
require("src/ui/panels/text_node")
require("src/ui/panels/message_log")
require("src/ui/ui_context_manager")

global record EventMessageLog
    is UIElement, TextUIElement
end
 
function EventMessageLog.new(props: MessageLog): EventMessageLog
    props.func = function(state: UIContextManager, _row_limit: integer): { string }
        return tmap(state.battle_ui_context.event_bus:get_event_history(), function(e: GameEvent): string return "> "..e  end)
    end

    return MessageLog.new(props) as EventMessageLog
end

return EventMessageLog
