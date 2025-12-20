require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")
require("src/tactics/animation")
-- require("src/tactics/ui/ui_context_manager")
global type UIContextManager

global record GameServiceBundle
	event_bus: EventBus
	task_manager: TaskManager
	animation_manager: AnimationManager
	ui_context: UIContextManager
end


return GameServiceBundle
