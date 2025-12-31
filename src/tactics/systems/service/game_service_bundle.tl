local EventBus = require("src/tactics/systems/event_bus").EventBus
local TaskManager = require("src/tactics/systems/tasks").TaskManager
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
local AnimationManager = require("src/tactics/animation").AnimationManager

local record GameServiceBundle
	event_bus: EventBus
	task_manager: TaskManager
	animation_manager: AnimationManager
	ui_context: UIContextManager
end


return {
	GameServiceBundle = GameServiceBundle
}
