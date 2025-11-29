require("src/debug")

global record TaskManager
    tasks: { any }
end

function TaskManager.new(): TaskManager
    return setmetatable({tasks = {}}, { __index = TaskManager })
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
