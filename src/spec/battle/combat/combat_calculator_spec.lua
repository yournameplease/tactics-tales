local luassert = require("luassert")
local combat_calculator = require("src.tactics.battle.combat.combat_calculator")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Always-valid targeting: any tile can attack any other tile.
local always_valid = { is_target_valid = function() return true end }
--- Out-of-range targeting: no attack is ever valid.
local out_of_range = { is_target_valid = function() return false end }

--- Build a minimal weapon table.
---@param damage integer
---@param accuracy integer
---@param effects? table[]
---@param targeting? table
---@return table
local function make_weapon(damage, accuracy, effects, targeting)
    return {
        damage = damage,
        accuracy = accuracy,
        targeting = targeting or always_valid,
        effects = effects or {},
    }
end

--- Build a minimal mock BattleUnit.
---@param opts table Fields: id, tile, hp, hp_max, weapons, items
---@return table
local function make_unit(opts)
    local weapons = opts.weapons or { make_weapon(5, 80) }
    local items = opts.items or {}
    return {
        id = opts.id or 1,
        tile = opts.tile or { x = 0, y = 0 },
        hp_current = opts.hp or 10,
        character = {
            stats = { hp_max = opts.hp_max or opts.hp or 10 },
            inventory = {
                get_equipped_weapons = function(_self) return weapons end,
                get_equipped_items = function(_self) return items end,
            },
        },
    }
end

--- Build a minimal mock BattleMap.
---@param dodge? integer Terrain dodge bonus (default 0).
---@return table
local function make_map(dodge)
    return {
        get_terrain = function(_self, _tile)
            return { dodge = dodge or 0 }
        end,
    }
end

-- rnd_returns(v) makes rnd always return v.
-- random.rndi(100) = math.floor(rnd(100)), so:
--   rnd_returns(0)  → hit_roll = 0  → hits any positive hit_chance
--   rnd_returns(99) → hit_roll = 99 → misses unless hit_chance = 100
local original_rnd = _G.rnd
after_each(function() _G.rnd = original_rnd end)

local function rnd_returns(val)
    return function(_limit) return val end
end
local function always_hit() _G.rnd = rnd_returns(0) end
local function always_miss() _G.rnd = rnd_returns(99) end

-- ---------------------------------------------------------------------------
-- compute_combat
-- ---------------------------------------------------------------------------

describe("combat_calculator.compute_combat", function()
    describe("basic attack", function()
        it("produces one step", function()
            always_hit()
            local att = make_unit({ id = 1, hp = 10, weapons = { make_weapon(5, 80) } })
            local def = make_unit({ id = 2, hp = 10, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(2, #result.steps)
        end)

        it("step1 is_hit = true when roll < hit_chance", function()
            always_hit()
            local att = make_unit({ weapons = { make_weapon(5, 80) } })
            local def = make_unit({ weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_true(result.steps[1].is_hit)
        end)

        it("step1 is_hit = false when roll >= hit_chance", function()
            always_miss()
            local att = make_unit({ weapons = { make_weapon(5, 80) } })
            local def = make_unit({ weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_false(result.steps[1].is_hit)
        end)

        it("attacker and defender references are correct in step", function()
            always_hit()
            local att = make_unit({ id = 1, weapons = { make_weapon(5, 80) } })
            local def = make_unit({ id = 2, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(att, result.steps[1].attacker)
            luassert.are_equal(def, result.steps[1].defender)
        end)
    end)

    describe("counterattack suppression", function()
        it("no counterattack when defender dies on first hit", function()
            always_hit()
            local att = make_unit({ hp = 10, weapons = { make_weapon(99, 100) } })
            local def = make_unit({ hp = 1, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(1, #result.steps)
        end)

        it("counterattack present when defender survives", function()
            always_hit()
            local att = make_unit({ hp = 10, weapons = { make_weapon(1, 80) } })
            local def = make_unit({ hp = 10, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(2, #result.steps)
        end)

        it("no counterattack when defender is out of range", function()
            always_hit()
            local att = make_unit({ hp = 10, weapons = { make_weapon(1, 80) } })
            local def = make_unit({ hp = 10, weapons = { make_weapon(3, 70, {}, out_of_range) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(1, #result.steps)
        end)

        it("no counterattack when attacker is all long_reach and defender is not", function()
            always_hit()
            local att = make_unit({
                hp = 10,
                weapons = { make_weapon(1, 80, { { type = "long_reach" } }) },
            })
            local def = make_unit({ hp = 10, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(1, #result.steps)
        end)

        it("counterattack present when both attacker and defender are long_reach", function()
            always_hit()
            local att = make_unit({
                hp = 10,
                weapons = { make_weapon(1, 80, { { type = "long_reach" } }) },
            })
            local def = make_unit({
                hp = 10,
                weapons = { make_weapon(3, 70, { { type = "long_reach" } }) },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(2, #result.steps)
        end)
    end)

    describe("damage calculation", function()
        it("damage = weapon.damage minus defender defense, min 1", function()
            always_hit()
            local att = make_unit({ weapons = { make_weapon(5, 100) } })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(3, 70) },
                items = { { equipment_effects = { { type = "increase_defense", defense_type = "ARMOR", amount = 2 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(3, result.steps[1].dmg) -- 5 - 2 = 3
        end)

        it("damage is minimum 1 when weapon has positive damage and defense absorbs all", function()
            always_hit()
            local att = make_unit({ weapons = { make_weapon(2, 100) } })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_defense", defense_type = "ARMOR", amount = 99 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(1, result.steps[1].dmg)
        end)

        it("armorkiller ignores ARMOR defense", function()
            always_hit()
            local att = make_unit({
                weapons = { make_weapon(5, 100, { { type = "armorkiller" } }) },
            })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_defense", defense_type = "ARMOR", amount = 4 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(5, result.steps[1].dmg) -- armor bypassed
        end)

        it("armorkiller does not ignore ARMOR defense penalties (negative amounts)", function()
            always_hit()
            local att = make_unit({
                weapons = { make_weapon(5, 100, { { type = "armorkiller" } }) },
            })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_defense", defense_type = "ARMOR", amount = -2 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(7, result.steps[1].dmg) -- penalty still applied: 5 - (-2) = 7
        end)

        it("shieldkiller ignores SHIELD defense", function()
            always_hit()
            local att = make_unit({
                weapons = { make_weapon(5, 100, { { type = "shieldkiller" } }) },
            })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_defense", defense_type = "SHIELD", amount = 3 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(5, result.steps[1].dmg) -- shield bypassed
        end)
    end)

    describe("hit chance calculation", function()
        it("hit_chance = accuracy - unit_avoid - terrain_dodge, clamped 0-100", function()
            always_hit()
            local att = make_unit({ weapons = { make_weapon(5, 80) } })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_avoid", avoid_type = "ARMOR", amount = 10 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map(5))
            luassert.are_equal(65, result.steps[1].hit_chance) -- 80 - 10 - 5
        end)

        it("hit_chance clamped to 0 when accuracy is very low", function()
            local att = make_unit({ weapons = { make_weapon(5, 10) } })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_avoid", avoid_type = "ARMOR", amount = 50 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(0, result.steps[1].hit_chance)
        end)

        it("hit_chance clamped to 100 when accuracy exceeds max", function()
            local att = make_unit({ weapons = { make_weapon(5, 120) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(1, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(100, result.steps[1].hit_chance)
        end)

        it("armorkiller ignores ARMOR avoid", function()
            always_hit()
            local att = make_unit({
                weapons = { make_weapon(5, 80, { { type = "armorkiller" } }) },
            })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_avoid", avoid_type = "ARMOR", amount = 20 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(80, result.steps[1].hit_chance) -- avoid bypassed
        end)

        it("avoid penalties are applied even when armorkiller is active", function()
            always_hit()
            local att = make_unit({
                weapons = { make_weapon(5, 80, { { type = "armorkiller" } }) },
            })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(1, 70) },
                items = { { equipment_effects = { { type = "increase_avoid", avoid_type = "ARMOR", amount = -10 } } } },
            })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.are_equal(90, result.steps[1].hit_chance) -- penalty applied: 80 - (-10)
        end)

        it("terrain dodge reduces hit_chance", function()
            local att = make_unit({ weapons = { make_weapon(5, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(1, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map(15))
            luassert.are_equal(65, result.steps[1].hit_chance) -- 80 - 15
        end)
    end)

    describe("hit/miss boundary", function()
        it("roll=84 with hit_chance=85 is a hit", function()
            _G.rnd = rnd_returns(84)
            local att = make_unit({ weapons = { make_weapon(5, 85) } })
            local def = make_unit({ weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_true(result.steps[1].is_hit)
        end)

        it("roll=85 with hit_chance=85 is a miss", function()
            _G.rnd = rnd_returns(85)
            local att = make_unit({ weapons = { make_weapon(5, 85) } })
            local def = make_unit({ weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_false(result.steps[1].is_hit)
        end)

        it("roll=86 with hit_chance=85 is a miss", function()
            _G.rnd = rnd_returns(86)
            local att = make_unit({ weapons = { make_weapon(5, 85) } })
            local def = make_unit({ weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_false(result.steps[1].is_hit)
        end)
    end)

    describe("weapon effects", function()
        it("shieldsplitter sets destroy_shield = true in the step", function()
            always_hit()
            local att = make_unit({
                weapons = { make_weapon(5, 80, { { type = "shieldsplitter" } }) },
            })
            local def = make_unit({ hp = 20, weapons = { make_weapon(1, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_true(result.steps[1].destroy_shield)
        end)

        it("weapon without shieldsplitter has destroy_shield = false", function()
            always_hit()
            local att = make_unit({ weapons = { make_weapon(5, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(1, 70) } })
            local result = combat_calculator.compute_combat(att, def, make_map())
            luassert.is_false(result.steps[1].destroy_shield)
        end)
    end)
end)

-- ---------------------------------------------------------------------------
-- preview_combat
-- ---------------------------------------------------------------------------

describe("combat_calculator.preview_combat", function()
    local attacker_tile = { x = 3, y = 3 }

    describe("expected_damage", function()
        it("equals attacker weapon damage minus defender defense", function()
            always_hit()
            local att = make_unit({ weapons = { make_weapon(6, 100) } })
            local def = make_unit({
                hp = 20,
                weapons = { make_weapon(3, 70) },
                items = { { equipment_effects = { { type = "increase_defense", defense_type = "ARMOR", amount = 2 } } } },
            })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.are_equal(4, result.expected_damage) -- 6 - 2
        end)
    end)

    describe("possible_kill", function()
        it("is true when expected_damage >= defender hp", function()
            local att = make_unit({ weapons = { make_weapon(10, 100) } })
            local def = make_unit({ hp = 5, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.is_true(result.possible_kill)
        end)

        it("is false when expected_damage < defender hp", function()
            local att = make_unit({ weapons = { make_weapon(3, 100) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.is_false(result.possible_kill)
        end)
    end)

    describe("possible_counterattack", function()
        it("is false when defender is out of range", function()
            local att = make_unit({ weapons = { make_weapon(3, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(3, 70, {}, out_of_range) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.is_false(result.possible_counterattack)
        end)

        it("is true when defender can counter", function()
            local att = make_unit({ weapons = { make_weapon(1, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.is_true(result.possible_counterattack)
        end)
    end)

    describe("expected_self_damage and possible_self_kill", function()
        it("expected_self_damage = 0 when no counterattack", function()
            local att = make_unit({ weapons = { make_weapon(3, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(3, 70, {}, out_of_range) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.are_equal(0, result.expected_self_damage)
        end)

        it("expected_self_damage equals defender weapon damage when counterattack occurs", function()
            local att = make_unit({ weapons = { make_weapon(1, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(7, 70) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.are_equal(7, result.expected_self_damage)
        end)

        it("possible_self_kill is true when expected_self_damage >= attacker hp", function()
            local att = make_unit({ hp = 3, weapons = { make_weapon(1, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(10, 70) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.is_true(result.possible_self_kill)
        end)

        it("possible_self_kill is false when expected_self_damage < attacker hp", function()
            local att = make_unit({ hp = 20, weapons = { make_weapon(1, 80) } })
            local def = make_unit({ hp = 20, weapons = { make_weapon(3, 70) } })
            local result = combat_calculator.preview_combat(att, def, attacker_tile, make_map())
            luassert.is_false(result.possible_self_kill)
        end)
    end)

    describe("attacker_tile override", function()
        it("uses attacker_tile for range validation, not unit's own tile", function()
            -- Targeting that only accepts attacks from tile {3,3}
            local position_targeting = {
                is_target_valid = function(from, _to, _map)
                    return from.x == 3 and from.y == 3
                end,
            }
            local att = make_unit({
                tile = { x = 0, y = 0 },
                weapons = { make_weapon(5, 80, {}, position_targeting) },
            })
            local def = make_unit({ hp = 20, weapons = { make_weapon(3, 70, {}, out_of_range) } })
            -- Attack from {3,3} → targeting succeeds
            local result = combat_calculator.preview_combat(att, def, { x = 3, y = 3 }, make_map())
            luassert.are_equal(1, #result.steps)
        end)
    end)
end)
