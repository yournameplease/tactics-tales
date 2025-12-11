
global type EventBus
global type TaskManager
global type AnimationManager

global record GameServiceBundle
	event_bus: EventBus
	task_manager: TaskManager
	animation_manager: AnimationManager
end


