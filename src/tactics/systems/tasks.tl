require("src/tactics/systems/service")
require("src/tactics/debug")

global record TaskManager
    is GameService
    where self.id == "task_manager"
    tasks: { any }
end

function TaskManager:init(_service_manager: ServiceManager, _services: { ServiceId: GameService })
    self.tasks = {}
end

function TaskManager.new(): TaskManager
    return setmetatable({
        id = "task_manager",
        dependencies = {},
    }, { __index = TaskManager })
end

function TaskManager:start_routine(func: function)
    local co = pt.cocreate(func) as any
    pt.add(self.tasks, co)
end

function TaskManager:update_tasks()
    for _,co in ipairs(self.tasks) do
        if pt.costatus(co) == "suspended" then
            local ok, err = pt.coresume(co)
            if not ok then
                LOG.error("Task Error: "..err)
                assert(ok)
            end
        elseif pt.costatus(co) == "dead" then
            pt.del(self.tasks, co)
        end
    end
end
