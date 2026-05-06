local luassert = require("luassert")
local event_bus = require("src.tactics.systems.event_bus")
local tasks = require("src.tactics.systems.tasks")
local turn_manager_mod = require("src.tactics.battle.turn_manager")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local orig_banner_duration

local function make_obj_svc(opts)
    opts = opts or {}
    return {
        check_objectives = function(_self)
            return opts.result or { finished = false }
        end,
        set_turn = function(_self, _turn) end,
    }
end

local function make_te(opts)
    opts = opts or {}
    return {
        turn = 1,
        phase_banner = nil,
        battle_is_blocked = false,
        refresh_all_units = opts.refresh_all_units or function(_self) end,
        yield_while_in_script = function(_self) end,
        show_phase_banner = function(_self, _text) end,
        tick_skill_cooldowns_for_side = function(_self, _side) end,
    }
end

local function make_map()
    return {
        get_units = function(_self, filter_fn)
            local all = {
                { side = "player", has_acted = false },
                { side = "neutral", has_acted = false },
                { side = "enemy", has_acted = false },
            }
            if not filter_fn then return all end
            local out = {}
            for _, u in ipairs(all) do
                if filter_fn(u) then table.insert(out, u) end
            end
            return out
        end,
    }
end

local function make_ai()
    return { handle_one_unit_action = function(_self, _side) end }
end

local function make_mmgr()
    return {
        set_menu = function(_self, _name) end,
        clear_menu = function(_self) end,
    }
end

local function make_tm(opts)
    opts = opts or {}
    local bus      = opts.bus      or event_bus.new()
    local task_mgr = opts.task_mgr or tasks.task_manager()
    local te       = opts.te       or make_te()
    local map      = opts.map      or make_map()
    local obj_svc  = opts.obj_svc  or make_obj_svc()
    local ai       = opts.ai       or make_ai()
    local mmgr     = opts.mmgr     or make_mmgr()
    local tm = turn_manager_mod.new(1, map, te, obj_svc, ai, bus, task_mgr, mmgr)
    return tm, bus, task_mgr
end

-- Pump until all coroutines have run to completion and been cleaned up.
-- update_tasks leaves dead coroutines in the list until the next pass, so we
-- keep pumping until is_idle() to avoid stale dead tasks blocking future runs.
local function pump(task_mgr)
    while not task_mgr:is_idle() do
        task_mgr:update_tasks()
    end
end

-- Advance through all three phases to complete one full turn cycle.
local function full_cycle(tm, task_mgr)
    tm:advance_phase() pump(task_mgr)
    tm:advance_phase() pump(task_mgr)
    tm:advance_phase() pump(task_mgr)
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("battle.turn_manager", function()
    before_each(function()
        orig_banner_duration = STATIC_CONFIG.PHASE_BANNER_DURATION
        STATIC_CONFIG.PHASE_BANNER_DURATION = 0
    end)

    after_each(function()
        STATIC_CONFIG.PHASE_BANNER_DURATION = orig_banner_duration
    end)

    -- -------------------------------------------------------------------------
    -- Phase cycling (AC1, AC2, AC3)
    -- -------------------------------------------------------------------------

    describe("acting_side", function()
        it("starts on player phase", function()
            local tm = make_tm()
            luassert.are_equal("player", tm:acting_side())
        end)
    end)

    describe("advance_phase", function()
        it("advances from player to neutral", function()
            local tm, _, task_mgr = make_tm()
            tm:advance_phase()
            pump(task_mgr)
            luassert.are_equal("neutral", tm:acting_side())
        end)

        it("advances from neutral to enemy", function()
            local tm, _, task_mgr = make_tm()
            tm:advance_phase() pump(task_mgr)
            tm:advance_phase() pump(task_mgr)
            luassert.are_equal("enemy", tm:acting_side())
        end)

        it("wraps from enemy back to player after a full cycle", function()
            local tm, _, task_mgr = make_tm()
            full_cycle(tm, task_mgr)
            luassert.are_equal("player", tm:acting_side())
        end)

        it("increments the turn counter after a full cycle", function()
            local tm, _, task_mgr = make_tm()
            luassert.are_equal(1, tm.turn)
            full_cycle(tm, task_mgr)
            luassert.are_equal(2, tm.turn)
        end)

        it("refreshes all units on turn boundary", function()
            local refreshed = false
            local te = make_te({ refresh_all_units = function(_self) refreshed = true end })
            local tm, _, task_mgr = make_tm({ te = te })
            full_cycle(tm, task_mgr)
            luassert.is_true(refreshed)
        end)
    end)

    -- -------------------------------------------------------------------------
    -- Objective evaluation (AC4, AC5, AC6)
    -- -------------------------------------------------------------------------

    describe("check_objectives", function()
        it("returns false when battle is ongoing", function()
            local tm = make_tm({ obj_svc = make_obj_svc({ result = { finished = false } }) })
            luassert.is_false(tm:check_objectives())
        end)

        it("emits BATTLE_END with VICTORY when victory condition is met", function()
            local bus = event_bus.new()
            local received = {}
            bus:on("BATTLE_END", function(args) table.insert(received, args) end)
            local tm = make_tm({
                bus = bus,
                obj_svc = make_obj_svc({ result = { finished = true, result = "VICTORY" } }),
            })
            local finished = tm:check_objectives()
            luassert.is_true(finished)
            luassert.are_equal(1, #received)
            luassert.are_equal("VICTORY", received[1].result)
        end)

        it("emits BATTLE_END with DEFEAT when failure condition is met", function()
            local bus = event_bus.new()
            local received = {}
            bus:on("BATTLE_END", function(args) table.insert(received, args) end)
            local tm = make_tm({
                bus = bus,
                obj_svc = make_obj_svc({ result = { finished = true, result = "DEFEAT" } }),
            })
            local finished = tm:check_objectives()
            luassert.is_true(finished)
            luassert.are_equal(1, #received)
            luassert.are_equal("DEFEAT", received[1].result)
        end)

        it("does not emit BATTLE_END when no conditions have resolved", function()
            local bus = event_bus.new()
            local battle_ended = false
            bus:on("BATTLE_END", function() battle_ended = true end)
            local tm = make_tm({
                bus = bus,
                obj_svc = make_obj_svc({ result = { finished = false } }),
            })
            tm:check_objectives()
            tm:check_objectives()
            luassert.is_false(battle_ended)
        end)
    end)
end)
