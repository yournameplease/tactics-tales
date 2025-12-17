
global type EventBus
global type TaskManager
global type AnimationManager
global type UIContextManager

global record GameServiceBundle
	event_bus: EventBus
	task_manager: TaskManager
	animation_manager: AnimationManager
	ui_context: UIContextManager
end


return GameServiceBundle
