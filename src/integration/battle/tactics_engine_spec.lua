local luassert           = require("luassert")
local battle_unit        = require("src.tactics.battle.tactics.battle_unit")
local tactics_engine_mod = require("src.tactics.battle.tactics.tactics_engine")
local event_bus_mod      = require("src.tactics.systems.event_bus")
local tasks              = require("src.tactics.systems.tasks")
local point              = require("src.tactics.util.point")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function make_character(opts)
    opts = opts or {}
    return {
        id            = opts.id or 1,
        name          = opts.name or "TestChar",
        stats         = { hp_max = opts.hp_max or 10, movement = 3 },
        dead          = false,
        tags          = opts.tags or {},
        skill_loadout = opts.skill_loadout or {},
        inventory     = {
            get_equipped_weapons = function() return {} end,
            get_equipped_items   = function() return {} end,
        },
    }
end

local function make_facing()
    return { turn_to = function(_self, _dir) end, face_point = function(_self, _d, _flip) end }
end

local function make_unit(opts)
    opts                = opts or {}
    local char          = opts.character or make_character(opts)
    local facing        = make_facing()
    local unit          = battle_unit.spawn_unit(
        char,
        opts.tile or point.of(0, 0),
        opts.tags or {},
        opts.side or "player",
        nil,
        facing,
        nil,
        opts.skill_defs
    )
    unit.animation_data = nil
    return unit
end

local function make_map(units)
    local by_tile = {}
    for _, u in ipairs(units) do
        by_tile[u.tile.x .. "," .. u.tile.y] = u
    end
    local map = {
        width  = 8,
        height = 8,
    }
    function map:get_at_tile(tile)
        return by_tile[tile.x .. "," .. tile.y]
    end

    function map:kill_unit(unit)
        by_tile[unit.tile.x .. "," .. unit.tile.y] = nil
    end

    function map:remove_unit(_id) end

    function map:get_unit_by_id(_id) return nil end

    function map:get_units(filter)
        local result = {}
        for _, u in pairs(by_tile) do
            if filter(u) then table.insert(result, u) end
        end
        return result
    end

    return map
end

local function make_animation_manager()
    return {
        create_idle_animation = function(_self) return { playing = false } end,
        create_animation      = function(_self, _name, _dir) return { playing = false } end,
        create_walk_animation = function(_self, _path, _offset) return { playing = false } end,
    }
end

local function make_music_player()
    return {
        push_music   = function(_self, ...) end,
        resume_music = function(_self, ...) end,
    }
end

local function make_char_manager()
    return { get_player_roster = function(_self) return {} end }
end

--- Build a TacticsEngine wired to a minimal mock stack.
--- Returns engine, task_manager, and an `emitted(type)` helper.
local function make_engine(units, skill_defs, opts)
    opts = opts or {}
    local bus = event_bus_mod.new()
    local emitted = {}
    local orig = bus.emit
    bus.emit = function(b, event_type, args)
        if not emitted[event_type] then emitted[event_type] = {} end
        table.insert(emitted[event_type], args or {})
        return orig(b, event_type, args)
    end

    local tm = tasks.task_manager()
    local engine = tactics_engine_mod.new(
        1,
        { permadeath = opts.permadeath or false },
        make_map(units),
        make_char_manager(),
        tm,
        make_animation_manager(),
        bus,
        make_music_player(),
        skill_defs or {}
    )

    local function emitted_fn(event_type)
        return emitted[event_type] or {}
    end

    return engine, tm, emitted_fn
end

local function tick_to_idle(tm)
    local limit = 1000
    local ticks = 0
    repeat
        tm:update_tasks()
        ticks = ticks + 1
        if ticks >= limit then
            error("tick_to_idle: exceeded " .. limit .. " ticks — possible infinite loop")
        end
    until tm:is_idle()
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics_engine handle_skill #it", function()
    describe("heal effect", function()
        it("restores heal_amount HP to the target", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(8, target.hp_current)
        end)

        it("clamps restored HP to hp_max", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 10, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 8

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(10, target.hp_current)
        end)
    end)

    describe("damage effect", function()
        it("applies flat damage to the target with no defense reduction", function()
            local skill_defs = {
                blast = { effect_type = "damage", damage = 5, accuracy = 100, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "blast" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "enemy",
                character = make_character({ id = 2, hp_max = 10 }),
            })

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "blast", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(5, target.hp_current)
        end)

        it("misses and deals no damage when accuracy is 0", function()
            local skill_defs = {
                blast = { effect_type = "damage", damage = 5, accuracy = 0, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "blast" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "enemy",
                character = make_character({ id = 2, hp_max = 10 }),
            })

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "blast", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(10, target.hp_current)
        end)
    end)

    describe("HP cost", function()
        it("deducts hp_cost from the caster before the effect", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = 2, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(8, caster.hp_current)
        end)

        it("fires the effect even if the HP cost kills the caster", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = 10, cooldown = nil },
            }
            -- Use enemy side to skip the player-death dialogue path.
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "enemy",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(8, target.hp_current)
        end)

        it("emits TACTICS_UNIT_DEATH when the HP cost kills the caster", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = 10, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "enemy",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm, emitted = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(1, #emitted("TACTICS_UNIT_DEATH"))
        end)
    end)

    describe("resource consumption", function()
        it("sets cooldown_remaining to skill.cooldown after use", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = nil, cooldown = 2 },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(2, caster.skill_states["heal"].cooldown_remaining)
        end)

        it("sets cooldown_remaining to 0 when the skill has no cooldown", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(0, caster.skill_states["heal"].cooldown_remaining)
        end)

        it("decrements uses_remaining after use", function()
            local skill_defs = {
                blast = { effect_type = "damage", damage = 1, accuracy = 100, hp_cost = nil, cooldown = nil, uses_per_battle = 3 },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "blast" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "enemy",
                character = make_character({ id = 2, hp_max = 10 }),
            })

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "blast", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(2, caster.skill_states["blast"].uses_remaining)
        end)

        it("leaves uses_remaining nil when the skill has no use cap", function()
            local skill_defs = {
                slash = { effect_type = "damage", damage = 1, accuracy = 100, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "slash" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "enemy",
                character = make_character({ id = 2, hp_max = 10 }),
            })

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "slash", target.tile)
            tick_to_idle(tm)

            luassert.is_nil(caster.skill_states["slash"].uses_remaining)
        end)
    end)

    describe("finish_unit_action", function()
        it("marks the caster as having acted", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.is_true(caster.has_acted)
        end)

        it("emits TACTICS_UNIT_END_ACTION", function()
            local skill_defs = {
                heal = { effect_type = "heal", heal_amount = 3, hp_cost = nil, cooldown = nil },
            }
            local caster = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "player",
                character = make_character({ id = 1, hp_max = 10, skill_loadout = { "heal" } }),
                skill_defs = skill_defs,
            })
            local target = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                character = make_character({ id = 2, hp_max = 10 }),
            })
            target.hp_current = 5

            local engine, tm, emitted = make_engine({ caster, target }, skill_defs)
            engine:handle_skill(caster, "heal", target.tile)
            tick_to_idle(tm)

            luassert.are_equal(1, #emitted("TACTICS_UNIT_END_ACTION"))
        end)
    end)
end)
