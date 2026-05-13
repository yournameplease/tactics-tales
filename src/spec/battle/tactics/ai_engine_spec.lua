local luassert = require("luassert")
local ai_engine = require("src.tactics.battle.tactics.ai_engine")
local battle_map = require("src.tactics.battle.battle_map")
local point = require("src.tactics.util.point")
local tasks = require("src.tactics.systems.tasks")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Melee targeting: valid when origin and target are Manhattan distance 1 apart.
--- Called as a dot-call: targeting.is_target_valid(origin, target_tile, map).
local melee_targeting = {
    is_target_valid = function(origin, target_tile, _map)
        local dx = math.abs(origin.x - target_tile.x)
        local dy = math.abs(origin.y - target_tile.y)
        return dx + dy == 1
    end,
}

--- Build a minimal weapon table compatible with combat_calculator.
---@param damage integer
---@param accuracy integer
---@return table
local function make_weapon(damage, accuracy)
    return {
        damage = damage,
        accuracy = accuracy,
        targeting = melee_targeting,
        effects = {},
    }
end

--- Build a defense item granting `amount` ARMOR defense.
---@param amount integer
---@return table
local function make_armor_item(amount)
    return {
        equipment_effects = {
            { type = "increase_defense", defense_type = "ARMOR", amount = amount },
        },
    }
end

--- Build a minimal BattleUnit mock.
--- opts fields: id, tile, side, movement_side, hp, hp_max, movement, weapons, items, unit_ai
---@param opts table
---@return table
local function make_unit(opts)
    local weapons = opts.weapons
    if weapons == nil then
        weapons = { make_weapon(5, 100) }
    end
    local items = opts.items or {}
    local char = {
        stats = {
            hp_max = opts.hp_max or opts.hp or 10,
            movement = opts.movement or 3,
        },
        inventory = {
            get_equipped_weapons = function(_self) return weapons end,
            get_equipped_items = function(_self) return items end,
        },
    }
    function char:get_weapon_targeting()
        return melee_targeting
    end

    local side = opts.side or "enemy"
    local unit = {
        id = opts.id or 1,
        tile = opts.tile or point.of(0, 0),
        side = side,
        movement_side = opts.movement_side or side,
        hp_current = opts.hp or 10,
        has_acted = false,
        unit_ai = opts.unit_ai or {
            move = "infinity",
            target_sides = { "player" },
            exclude_tags = nil,
        },
        character = char,
    }
    function unit:has_tag(_tag) return false end

    return unit
end

--- Build a real BattleMap, spawn units onto it, and configure terrain layers.
--- All tiles default to sprite 1 (walkable, movement_cost 1).
--- terrain_overrides: list of {x, y, sprite} to override individual tiles.
--- Sprite encoding (set globally in before_each):
---   sprite 1 → fget returns 0  → terrain 0 → movement_cost 1  (normal)
---   sprite 2 → fget returns 8  → terrain 4 → movement_cost 4  (mountain)
---@param units_list table[]
---@param width integer
---@param height integer
---@param terrain_overrides? {x:integer, y:integer, sprite:integer}[]
---@return BattleMap
local function make_battle_map(units_list, width, height, terrain_overrides)
    width = width or 5
    height = height or 5
    local map = battle_map.new(width, height, {})
    local ground = userdata("u8", width, height)
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            ground:set(x, y, 1)
        end
    end
    if terrain_overrides then
        for _, t in ipairs(terrain_overrides) do
            ground:set(t.x, t.y, t.sprite)
        end
    end
    ---@diagnostic disable-next-line: missing-fields
    map.layers = {
        terrain = {
            ground     = ground,
            back_wall  = userdata("u8", width, height),
            mid_wall   = userdata("u8", width, height),
            front_wall = userdata("u8", width, height),
        },
    }
    for _, u in ipairs(units_list) do
        map:spawn_unit(u, u.tile)
    end
    return map
end

--- Build a TacticsEngine spy that records the last dispatched method and its arguments.
---@return table
local function make_tactics_spy()
    local spy = { method = nil, args = {} }
    function spy:handle_move_and_attack(unit, dest, path, target)
        self.method = "handle_move_and_attack"
        self.args = { unit = unit, dest = dest, path = path, target = target }
    end

    function spy:handle_move_and_wait(unit, dest, path)
        self.method = "handle_move_and_wait"
        self.args = { unit = unit, dest = dest, path = path }
    end

    return spy
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("ai_engine", function()
    before_each(function()
        -- sprite 2: fget returns 8 (bit 3 set) → (8 & 0xD) >> 1 = 4 → mountain, movement_cost 4
        fset(2, 3, true)
    end)

    describe("compute_unit_ai", function()
        it("attacks an adjacent enemy in one move", function()
            -- AI unit at (0,0); enemy at (0,1) — melee range from (0,0).
            local ai_unit = make_unit({ id = 1, tile = point.of(0, 0), side = "enemy", movement = 1 })
            local enemy   = make_unit({ id = 2, tile = point.of(0, 1), side = "player", hp = 10 })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_attack", spy.method)
            luassert.are_equal(enemy.id, spy.args.target.id)
        end)

        it("moves one step toward a distant enemy when out of attack range", function()
            -- AI at (0,0) with movement=1; enemy at (4,0) — reachable only after multiple turns.
            -- Expected: AI moves to (1,0), one step along the direct path.
            local ai_unit = make_unit({ id = 1, tile = point.of(0, 0), side = "enemy", movement = 1 })
            local enemy   = make_unit({ id = 2, tile = point.of(4, 0), side = "player", hp = 10 })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy }, 5, 5), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_wait", spy.method)
            luassert.are_equal(1, spy.args.dest.x)
            luassert.are_equal(0, spy.args.dest.y)
        end)

        it("waits in place when no targets exist", function()
            local ai_unit = make_unit({ id = 1, tile = point.of(1, 1), side = "enemy", movement = 2 })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_wait", spy.method)
            luassert.are_equal(1, spy.args.dest.x)
            luassert.are_equal(1, spy.args.dest.y)
        end)

        it("prefers a killing attack over a non-killing attack", function()
            -- enemy_a has 1 HP: a 5-damage hit guarantees a kill (possible_kill = true).
            -- enemy_b has 999 HP: no kill possible.
            -- Both are adjacent and unarmed (no counterattack, equal self-damage).
            local ai_unit = make_unit({ id = 1, tile = point.of(1, 1), side = "enemy", movement = 2, hp = 20, hp_max = 20 })
            local enemy_a = make_unit({ id = 2, tile = point.of(1, 0), side = "player", hp = 1, hp_max = 10, weapons = {} })
            local enemy_b = make_unit({ id = 3, tile = point.of(1, 2), side = "player", hp = 999, hp_max = 999, weapons = {} })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy_a, enemy_b }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_attack", spy.method)
            luassert.are_equal(enemy_a.id, spy.args.target.id)
        end)

        it("avoids self-kill when a safe target exists", function()
            -- AI has 1 HP. enemy_a has a weapon: counterattack would kill the AI (possible_self_kill).
            -- enemy_b is unarmed: no counterattack, no self-kill risk.
            -- Neither target is killable (hp=999 > 5 damage).
            local ai_unit = make_unit({ id = 1, tile = point.of(1, 1), side = "enemy", movement = 2, hp = 1, hp_max = 20 })
            local enemy_a = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                hp = 999,
                hp_max = 999,
                weapons = { make_weapon(5, 100) }
            })
            local enemy_b = make_unit({
                id = 3,
                tile = point.of(1, 2),
                side = "player",
                hp = 999,
                hp_max = 999,
                weapons = {}
            })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy_a, enemy_b }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_attack", spy.method)
            luassert.are_equal(enemy_b.id, spy.args.target.id)
        end)

        it("avoids counterattack when an unarmed target exists", function()
            -- AI has enough HP to survive a counterattack (no self-kill), but still prefers to avoid it.
            -- enemy_a has a weak weapon (possible_counterattack = true, no self-kill risk).
            -- enemy_b is unarmed (possible_counterattack = false).
            -- Neither target is killable.
            local ai_unit = make_unit({ id = 1, tile = point.of(1, 1), side = "enemy", movement = 2, hp = 20, hp_max = 20 })
            local enemy_a = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                hp = 999,
                hp_max = 999,
                weapons = { make_weapon(1, 100) }
            })
            local enemy_b = make_unit({
                id = 3,
                tile = point.of(1, 2),
                side = "player",
                hp = 999,
                hp_max = 999,
                weapons = {}
            })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy_a, enemy_b }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_attack", spy.method)
            luassert.are_equal(enemy_b.id, spy.args.target.id)
        end)

        it("prefers the target where more damage can be dealt", function()
            -- Both enemies: unarmed (no counterattack), not killable (hp=999), equal kill/self-kill.
            -- enemy_a has no defense: expected_damage = 5 (full weapon damage).
            -- enemy_b has massive armor: expected_damage = 1 (minimum floor).
            -- AI should pick enemy_a (higher expected_damage).
            local ai_unit = make_unit({ id = 1, tile = point.of(1, 1), side = "enemy", movement = 2, hp = 20, hp_max = 20 })
            local enemy_a = make_unit({
                id = 2,
                tile = point.of(1, 0),
                side = "player",
                hp = 999,
                hp_max = 999,
                weapons = {},
                items = {}
            })
            local enemy_b = make_unit({
                id = 3,
                tile = point.of(1, 2),
                side = "player",
                hp = 999,
                hp_max = 999,
                weapons = {},
                items = { make_armor_item(999) }
            })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy_a, enemy_b }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_attack", spy.method)
            luassert.are_equal(enemy_a.id, spy.args.target.id)
        end)

        it("does not move or attack when ai.move is zero and the enemy requires movement to reach", function()
            -- Enemy is at (0,2): attackable from (0,1) (melee), but not from (0,0).
            -- With ai.move="zero", max_move=0 and shallow_move_limit=0, so pathfinding only
            -- covers the starting tile (cost=0). The unit cannot move to (0,1), so no
            -- attack position is found and the unit waits in place.
            local ai_unit = make_unit({
                id = 1,
                tile = point.of(0, 0),
                side = "enemy",
                movement = 3,
                unit_ai = { move = "zero", target_sides = { "player" }, exclude_tags = nil },
            })
            local enemy   = make_unit({ id = 2, tile = point.of(0, 2), side = "player", hp = 10 })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(make_battle_map({ ai_unit, enemy }, 3, 3), spy, tasks.task_manager())

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_wait", spy.method)
            luassert.are_equal(0, spy.args.dest.x)
            luassert.are_equal(0, spy.args.dest.y)
        end)

        it("takes a low-cost detour when the direct path has expensive terrain", function()
            -- 5x2 map.  Tile (1,0) is mountain terrain (movement_cost 4, sprite 2).
            -- With movement=2 the AI cannot afford the direct row-0 path; it must detour
            -- via row 1.  Both candidate attack positions ((3,0) and (4,1)) have the same
            -- total movement cost and both trace back through (1,1) after back-tracking
            -- within the movement budget — so the AI stops at (1,1).
            local ai_unit = make_unit({ id = 1, tile = point.of(0, 0), side = "enemy", movement = 2 })
            local enemy   = make_unit({ id = 2, tile = point.of(4, 0), side = "player", hp = 10 })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(
                make_battle_map({ ai_unit, enemy }, 5, 2, { { x = 1, y = 0, sprite = 2 } }),
                spy, tasks.task_manager()
            )

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_wait", spy.method)
            luassert.are_equal(1, spy.args.dest.x)
            luassert.are_equal(1, spy.args.dest.y)
        end)

        it("waits in place when the preferred attack tile is occupied by an ally", function()
            -- 3x2 map.  AI at (0,0), movement=1.  An ally occupies (1,0), which is the
            -- only tile within movement range that is adjacent to the enemy at (2,0).
            -- Pathfinding can still traverse through (1,0) (same movement_side), so the
            -- deep-action search finds (1,0) as the cheapest attack position.  However,
            -- tile_is_legal_destination returns false for (1,0), so the back-tracking
            -- loop steps back to (0,0) and the AI waits in place.
            local ai_unit = make_unit({ id = 1, tile = point.of(0, 0), side = "enemy", movement = 1 })
            local ally    = make_unit({ id = 3, tile = point.of(1, 0), side = "enemy", movement = 1 })
            local enemy   = make_unit({ id = 2, tile = point.of(2, 0), side = "player", hp = 10 })
            local spy     = make_tactics_spy()
            local engine  = ai_engine.new(
                make_battle_map({ ai_unit, ally, enemy }, 3, 2),
                spy, tasks.task_manager()
            )

            engine:compute_unit_ai(ai_unit)

            luassert.are_equal("handle_move_and_wait", spy.method)
            luassert.are_equal(0, spy.args.dest.x)
            luassert.are_equal(0, spy.args.dest.y)
        end)
    end)
end)
