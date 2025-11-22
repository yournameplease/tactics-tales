local tasks = {}

function start_routine(func)
    local co = cocreate(func)
    add(tasks, co)
end

function update_tasks()
    for co in all(tasks) do
        if costatus(co) == "suspended" then
            local ok, err = coresume(co)
            if not ok then
                printh("Task Error: "..err)
                assert(ok)
            end
        elseif costatus(co) == "dead" then
            del(tasks, co)
        end
    end
end