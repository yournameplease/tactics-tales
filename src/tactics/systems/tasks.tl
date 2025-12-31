require("src/tactics/debug")

global record TaskManager
    tasks: { any }
end

function TaskManager.new(): TaskManager
    return setmetatable({
        tasks = {},
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
