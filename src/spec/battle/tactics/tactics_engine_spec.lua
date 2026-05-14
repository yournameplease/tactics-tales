local luassert = require("luassert")
local te_module = require("src.tactics.battle.tactics.tactics_engine")
local TacticsEngine = te_module.TacticsEngine
local unit_spawner = require("src.tactics.battle.unit_spawner")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@param damage integer
---@param accuracy integer
---@return table
local function make_damage_skill(damage, accuracy)
    return {
        effects = { { type = "damage", damage = damage, accuracy = accuracy } },
    }
end

---@param hp integer
---@param active_statuses? table[]
---@return table
local function make_target(hp, active_statuses)
    local t = {
        hp_current = hp,
        active_statuses = active_statuses or {},
    }
    function t:take_damage(amount)
        self.hp_current = self.hp_current - amount
    end
    return t
end

---@param skill_id string
---@return table
local function make_caster(skill_id)
    return {
        hp_current = 20,
        has_acted = false,
        skill_states = { [skill_id] = { cooldown_remaining = 0 } },
        active_statuses = {},
        facing = { turn_to = function() end },
        animation_data = nil,
        take_damage = function(self, amount) self.hp_current = self.hp_current - amount end,
    }
end

---@param skill_defs table<string, table>
---@return table
local function make_stub_engine(skill_defs)
    return {
        skill_defs = skill_defs,
        battle_is_blocked = false,
        animation_manager = { create_idle_animation = function() return {} end },
        event_writer = { emit = function() end },
        finish_unit_action = function(_, unit) unit.has_acted = true end,
        kill_unit = function() end,
    }
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.battle.tactics.tactics_engine", function()

    -- -----------------------------------------------------------------------
    -- skill_action: damage effect
    -- -----------------------------------------------------------------------

    -- -----------------------------------------------------------------------
    -- spawn_units: disabled field
    -- -----------------------------------------------------------------------

    describe("spawn_units disabled field", function()
        local orig_try_spawn_at
        local stub_unit

        ---@return table
        local function make_spawn_engine()
            return {
                character_manager = {
                    get_player_roster = function() return {} end,
                },
                battle_map = {
                    get_tiles_by_label = function(_, _) return { { x = 1, y = 1 } } end,
                },
            }
        end

        ---@param disabled? boolean
        ---@return table
        local function make_unit_spawn_data(disabled)
            return {
                tile = "start",
                character_source = { type = "template", template = "warrior" },
                side = "enemy",
                disabled = disabled,
            }
        end

        before_each(function()
            orig_try_spawn_at = unit_spawner.try_spawn_at
            stub_unit = { id = 1 }
            ---@diagnostic disable-next-line: duplicate-set-field
            unit_spawner.try_spawn_at = function(_, _, _, roster_count)
                return stub_unit, roster_count
            end
        end)

        after_each(function()
            unit_spawner.try_spawn_at = orig_try_spawn_at
        end)

        it("disabled=true sets unit.disabled to true", function()
            local engine = make_spawn_engine()
            local spawned = TacticsEngine.spawn_units(engine, { make_unit_spawn_data(true) }, "prevent")
            luassert.is_true(spawned[1].disabled)
        end)

        it("disabled=false leaves unit.disabled false", function()
            local engine = make_spawn_engine()
            local spawned = TacticsEngine.spawn_units(engine, { make_unit_spawn_data(false) }, "prevent")
            luassert.is_false(spawned[1].disabled)
        end)

        it("absent disabled field leaves unit.disabled false", function()
            local engine = make_spawn_engine()
            local spawned = TacticsEngine.spawn_units(engine, { make_unit_spawn_data(nil) }, "prevent")
            luassert.is_false(spawned[1].disabled)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- skill_action: damage effect
    -- -----------------------------------------------------------------------

    describe("skill_action damage effect", function()
        it("applies base damage to target on hit", function()
            local skill_id = "test_dmg"
            local engine = make_stub_engine({ [skill_id] = make_damage_skill(3, 100) })
            local caster = make_caster(skill_id)
            local target = make_target(10)

            TacticsEngine.skill_action(engine, caster, skill_id, target)

            luassert.are_equal(7, target.hp_current)
        end)
    end)
end)
