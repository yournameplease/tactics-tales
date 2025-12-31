local event_bus = require("src/tactics/systems/event_bus")
local tasks = require("src/tactics/systems/tasks")
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
require("src/tactics/animation")

local record GameServiceBundle
	event_bus: event_bus.EventBus
	task_manager: tasks.TaskManager
	animation_manager: AnimationManager
	ui_context: UIContextManager
end


return {
	GameServiceBundle = GameServiceBundle
}
