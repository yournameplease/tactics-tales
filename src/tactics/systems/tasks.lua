---@brief
--- A simple task manager that runs routines as coroutines.

---@class TaskManager
---@field tasks any[] Active coroutines being managed.
local TaskManager = {}
TaskManager.__index = TaskManager

local tasks = {}

--- Create a new TaskManager.
---@return TaskManager
function tasks.task_manager()
    ---@type TaskManager
    local self = setmetatable({}, TaskManager)
    self.tasks = {}
    return self
end

--- Wrap func in a coroutine and add it to the task list.
---@param func function
function TaskManager:start_routine(func)
    local co = cocreate(func)
    table.insert(self.tasks, co)
end

--- Resume all suspended tasks; remove dead ones. Errors on coroutine failure.
function TaskManager:update_tasks()
    for _, co in ipairs(self.tasks) do
        if costatus(co) == "suspended" then
            local ok, err = coresume(co)
            if not ok then
                log.error("Task Error: " .. err)
                assert(ok, "An error occurred in a coroutine.  Let the developer know!")
            end
        elseif costatus(co) == "dead" then
            del(self.tasks, co)
        end
    end
end

return tasks
