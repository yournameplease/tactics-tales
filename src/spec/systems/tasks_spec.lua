local luassert = require("luassert")

local tasks = require("src.tactics.systems.tasks")

describe("tactics.systems.tasks", function()
    describe("task_manager", function()
        it("should create a manager with an empty task list", function()
            local tm = tasks.task_manager()
            luassert.are_equal(0, #tm.tasks)
        end)
    end)

    describe("start_routine", function()
        it("should add the coroutine to the task list", function()
            local tm = tasks.task_manager()
            tm:start_routine(function() end)
            luassert.are_equal(1, #tm.tasks)
        end)

        it("should add multiple routines independently", function()
            local tm = tasks.task_manager()
            tm:start_routine(function() end)
            tm:start_routine(function() end)
            luassert.are_equal(2, #tm.tasks)
        end)
    end)

    describe("update_tasks", function()
        it("should resume a suspended coroutine", function()
            local tm = tasks.task_manager()
            local ran = false
            tm:start_routine(function()
                ran = true
            end)
            tm:update_tasks()
            luassert.is_true(ran)
        end)

        it("should resume a yielding coroutine on each update", function()
            local tm = tasks.task_manager()
            local count = 0
            tm:start_routine(function()
                count = count + 1
                coroutine.yield()
                count = count + 1
            end)
            tm:update_tasks()
            luassert.are_equal(1, count)
            tm:update_tasks()
            luassert.are_equal(2, count)
        end)

        it("should remove a dead coroutine on the following update", function()
            local tm = tasks.task_manager()
            tm:start_routine(function() end)
            tm:update_tasks()
            -- coroutine ran to completion but removal happens on next update
            luassert.are_equal(1, #tm.tasks)
            tm:update_tasks()
            luassert.are_equal(0, #tm.tasks)
        end)

        it("should error when a coroutine raises an error", function()
            local tm = tasks.task_manager()
            tm:start_routine(function()
                error("boom")
            end)
            luassert.has_error(function()
                tm:update_tasks()
            end)
        end)
    end)

    describe("is_idle", function()
        it("should return true when no tasks are queued", function()
            local tm = tasks.task_manager()
            luassert.is_true(tm:is_idle())
        end)

        it("should return false while a task is pending", function()
            local tm = tasks.task_manager()
            tm:start_routine(function() coroutine.yield() end)
            luassert.is_false(tm:is_idle())
        end)

        it("should return true after all tasks run and are cleaned up", function()
            local tm = tasks.task_manager()
            tm:start_routine(function() end)
            tm:update_tasks() -- runs task to completion; task still in list as dead
            tm:update_tasks() -- cleans up dead task
            luassert.is_true(tm:is_idle())
        end)
    end)
end)
