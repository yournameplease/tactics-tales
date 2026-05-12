local luassert = require("luassert")
local te_module = require("src.tactics.battle.tactics.tactics_engine")
local TacticsEngine = te_module.TacticsEngine

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
    -- skill_action: mark debuff bonus damage (TASK-122)
    -- -----------------------------------------------------------------------

    describe("skill_action mark debuff bonus", function()
        it("applies base damage when target has no mark status", function()
            local skill_id = "test_dmg"
            local engine = make_stub_engine({ [skill_id] = make_damage_skill(3, 100) })
            local caster = make_caster(skill_id)
            local target = make_target(10)

            TacticsEngine.skill_action(engine, caster, skill_id, target)

            luassert.are_equal(7, target.hp_current)
        end)

        it("adds mark amount to damage when target has mark debuff", function()
            local skill_id = "test_dmg"
            local engine = make_stub_engine({ [skill_id] = make_damage_skill(3, 100) })
            local caster = make_caster(skill_id)
            local target = make_target(10, { { kind = "mark", amount = 2, duration = 1 } })

            TacticsEngine.skill_action(engine, caster, skill_id, target)

            luassert.are_equal(5, target.hp_current)
        end)

        it("uses only the first mark status amount", function()
            local skill_id = "test_dmg"
            local engine = make_stub_engine({ [skill_id] = make_damage_skill(1, 100) })
            local caster = make_caster(skill_id)
            local target = make_target(10, {
                { kind = "mark", amount = 3, duration = 1 },
                { kind = "mark", amount = 5, duration = 1 },
            })

            TacticsEngine.skill_action(engine, caster, skill_id, target)

            -- Only first mark is consumed (loop breaks after first match)
            luassert.are_equal(6, target.hp_current)
        end)
    end)
end)
