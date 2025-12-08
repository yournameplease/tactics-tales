require("src/systems/service")
require("src/debug")

global record TaskManager
    is GameService
    where self.id == "task_manager"
    tasks: { any }
end

function TaskManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
    self.tasks = {}
end

function TaskManager.new(): TaskManager
    return setmetatable({
        id = "task_manager",
        dependencies = {},
    }, { __index = TaskManager })
end

function TaskManager:start_routine(func: function)
    local co = cocreate(func) as any
    add(self.tasks, co)
end

function TaskManager:update_tasks()
    for _,co in ipairs(self.tasks) do
        if costatus(co) == "suspended" then
            local ok, err = coresume(co)
            if not ok then
                LOG.error("Task Error: "..err)
                assert(ok)
            end
        elseif costatus(co) == "dead" then
            del(self.tasks, co)
        end
    end
end
