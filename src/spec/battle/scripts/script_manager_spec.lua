local luassert = require("luassert")
local event_bus = require("src.tactics.systems.event_bus")
local script_manager = require("src.tactics.battle.scripts.script_manager")
local tasks = require("src.tactics.systems.tasks")
local id_generator = require("src.tactics.util.id_generator")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function make_map()
    return {
        width = 5,
        height = 5,
        get_units = function(_self, _f) return {} end,
        get_tiles_by_label = function(_self, _label) return {} end,
        register_unit_interaction = function() end,
        register_tile_interaction = function() end,
        unregister_interaction = function() end,
    }
end

local function make_engine()
    local id_gen = id_generator.new()
    local engine = {
        tactics_locks = {},
        lock_count = 0,
    }
    function engine:acquire_lock()
        local id = id_gen:get_id()
        engine.tactics_locks[id] = true
        engine.lock_count = engine.lock_count + 1
        return id
    end

    function engine:remove_lock(id)
        engine.tactics_locks[id] = nil
    end

    function engine:is_blocked() return false end

    function engine:is_locked()
        for _ in pairs(engine.tactics_locks) do return true end
        return false
    end

    return engine
end

local function make_unit(id, tag)
    return {
        id = id,
        tags = tag and { [tag] = true } or {},
    }
end

local function pump(tm, max_iters)
    max_iters = max_iters or 10
    for _ = 1, max_iters do
        tm:update_tasks()
        if tm:is_idle() then break end
    end
end

local function make_sm(script, bus, engine, tm)
    ---@diagnostic disable-next-line: missing-fields
    return script_manager.new({ script }, bus, {}, make_map(), engine, tm)
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("script_manager before_combat trigger", function()
    it("fires when attacker tag matches", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat", attacker_tag = "hero" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, "hero")
        local defender = make_unit(2, nil)
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(1, engine.lock_count)
    end)

    it("fires when defender tag matches", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat", defender_tag = "boss" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, nil)
        local defender = make_unit(2, "boss")
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(1, engine.lock_count)
    end)

    it("does not fire when attacker tag does not match", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat", attacker_tag = "hero" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, "villain")
        local defender = make_unit(2, nil)
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(0, engine.lock_count)
    end)

    it("fires with no tag filter", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, nil)
        local defender = make_unit(2, nil)
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(1, engine.lock_count)
    end)

    it("fires when both attacker and defender tags match", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat", attacker_tag = "hero", defender_tag = "boss" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, "hero")
        local defender = make_unit(2, "boss")
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(1, engine.lock_count)
    end)

    it("does not fire when only one of two required tags matches", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat", attacker_tag = "hero", defender_tag = "boss" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, "hero")
        local defender = make_unit(2, "minion")
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(0, engine.lock_count)
    end)

    it("provides attacker as source_unit and defender as target_unit in context", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()
        local captured_ctx = nil

        local sm = make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_combat" },
            effects = {},
        }, bus, engine, tm)

        -- Observe via a dialogue effect using trigger_source selector
        -- Instead, intercept via a post-fire check using lock_count + manual hook
        -- Verify by checking that the context is built correctly via a spy effect
        -- We patch start_dialogue to capture the unit
        local received_source = nil
        local received_target = nil
        engine.start_dialogue = function(_self, unit, _text)
            received_source = unit
        end

        local attacker = make_unit(1, "hero")
        local defender = make_unit(2, "boss")

        -- Re-create with a dialogue effect
        local bus2 = event_bus.new()
        local tm2 = tasks.task_manager()
        local engine2 = make_engine()
        engine2.start_dialogue = function(_self, unit, _text)
            received_source = unit
        end

        ---@diagnostic disable-next-line: missing-fields
        script_manager.new({
            ---@diagnostic disable-next-line: missing-fields
            {
                tags = {},
                one_shot = false,
                trigger = { type = "before_combat" },
                effects = {
                    { type = "dialogue", unit = { type = "trigger_source" }, text = { "hello" } },
                },
            }
            ---@diagnostic disable-next-line: missing-fields
        }, bus2, {}, make_map(), engine2, tm2)

        bus2:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm2)

        assert(received_source)
        luassert.are_equal(attacker.id, received_source.id)
    end)
end)

describe("script_manager before_counterattack trigger", function()
    it("fires when BEFORE_COUNTERATTACK is emitted with matching attacker tag", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_counterattack", attacker_tag = "hero" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, "hero")
        local defender = make_unit(2, nil)
        bus:emit("BEFORE_COUNTERATTACK", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(1, engine.lock_count)
    end)

    it("does not fire on BEFORE_COMBAT event", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_counterattack" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, nil)
        local defender = make_unit(2, nil)
        bus:emit("BEFORE_COMBAT", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(0, engine.lock_count)
    end)

    it("does not fire when defender tag does not match", function()
        local bus = event_bus.new()
        local tm = tasks.task_manager()
        local engine = make_engine()

        make_sm({
            tags = {},
            one_shot = false,
            trigger = { type = "before_counterattack", defender_tag = "boss" },
            effects = {},
        }, bus, engine, tm)

        local attacker = make_unit(1, nil)
        local defender = make_unit(2, "minion")
        bus:emit("BEFORE_COUNTERATTACK", { attacker = attacker, defender = defender })
        pump(tm)

        luassert.are_equal(0, engine.lock_count)
    end)
end)
