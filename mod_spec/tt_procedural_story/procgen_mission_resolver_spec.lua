local luassert       = require("luassert")

local resolver_mod   = require("tt_procedural_campaign.lib.procgen_mission_resolver")
local compute_seed   = resolver_mod._compute_seed
local build_units    = resolver_mod._build_units
local campaign_state = require("src.tactics.campaign.campaign_state")
local random         = require("src.tactics.util.random")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@param opts? {faction_id?: string, tier?: integer}
local function make_config(opts)
    opts = opts or {}
    ---@diagnostic disable-next-line: missing-fields
    local mem = campaign_state.new({ get_character = function() return nil end })
    if opts.faction_id then mem:set("faction_id",     campaign_state.text(opts.faction_id)) end
    if opts.tier       then mem:set("base_difficulty", campaign_state.text(tostring(opts.tier))) end
    return { memory = mem }
end

---@param seed? integer
---@return CampaignRngContext
local function make_rng_context(seed)
    return { battle_rng = random.new(seed or 1) }
end

---@param tile_labels table<string, any[]>
---@param spawn_label_meta table<string, {role: string, tags: string[]?}>
---@return BattleMap
local function make_battle_map(tile_labels, spawn_label_meta)
    ---@diagnostic disable-next-line: missing-fields
    return { tile_labels = tile_labels or {}, spawn_label_meta = spawn_label_meta or {} }
end

-- ---------------------------------------------------------------------------
-- compute_seed
-- ---------------------------------------------------------------------------

describe("tt_procedural_campaign.lib.procgen_mission_resolver", function()
    describe("_compute_seed", function()
        it("returns a numeric value", function()
            luassert.are_equal("number", type(compute_seed(make_rng_context(7))))
        end)

        it("returns 0 when rng_context is nil", function()
            luassert.are_equal(0, compute_seed(nil))
        end)

        it("produces different values for different rng states", function()
            local ctx1 = make_rng_context(1)
            local ctx2 = make_rng_context(9999)
            luassert.are_not_equal(compute_seed(ctx1), compute_seed(ctx2))
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- build_units
    -- ---------------------------------------------------------------------------

    describe("_build_units", function()
        it("always includes a player unit with tile player_deployment", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local units = build_units(cfg, make_battle_map({}, {}))
            local found = false
            for _, u in ipairs(units) do
                if u.side == "player" and u.tile == "player_deployment" then
                    found = true; break
                end
            end
            luassert.is_true(found)
        end)

        it("emits exactly one enemy unit per label regardless of point count", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { enemy_infantry = { { x = 3, y = 4 }, { x = 5, y = 6 } } },
                { enemy_infantry = { role = "enemy_infantry" } }
            )
            local units = build_units(cfg, map)
            local count = 0
            for _, u in ipairs(units) do
                if u.tile == "enemy_infantry" and u.side == "enemy" then count = count + 1 end
            end
            luassert.are_equal(1, count)
        end)

        it("emits one enemy unit for enemy_commander label", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { enemy_commander = { { x = 8, y = 8 } } },
                { enemy_commander = { role = "enemy_commander" } }
            )
            local units = build_units(cfg, map)
            local count = 0
            for _, u in ipairs(units) do
                if u.tile == "enemy_commander" and u.side == "enemy" then count = count + 1 end
            end
            luassert.are_equal(1, count)
        end)

        it("skips labels with no meta entry", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { some_unknown_label = { { x = 1, y = 1 } } },
                {}
            )
            local units = build_units(cfg, map)
            luassert.are_equal(1, #units)
        end)

        it("skips labels whose role is 'player'", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { player_deployment = { { x = 1, y = 1 } } },
                { player_deployment = { role = "player" } }
            )
            local units = build_units(cfg, map)
            luassert.are_equal(1, #units)
        end)

        it("uses the faction tier to select the character template", function()
            local cfg = make_config({ faction_id = "bandits", tier = 2 })
            local map = make_battle_map(
                { enemy_infantry = { { x = 1, y = 1 } } },
                { enemy_infantry = { role = "enemy_infantry" } }
            )
            local units = build_units(cfg, map)
            local enemy
            for _, u in ipairs(units) do
                if u.side == "enemy" then enemy = u; break end
            end
            -- Bandits tier 2 infantry = "bandit_axe"
            luassert.are_equal("template", enemy.character_source.type)
            luassert.are_equal("bandit_axe", enemy.character_source.template)
        end)

        it("enemy_commander units use stationary AI", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { enemy_commander = { { x = 5, y = 5 } } },
                { enemy_commander = { role = "enemy_commander" } }
            )
            local units = build_units(cfg, map)
            local found_stationary = false
            for _, u in ipairs(units) do
                if u.tile == "enemy_commander" and u.ai ~= nil then
                    found_stationary = true; break
                end
            end
            luassert.is_true(found_stationary)
        end)

        it("boss labels carry the tags field from meta", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { enemy_tank_boss = { { x = 2, y = 2 } } },
                { enemy_tank_boss = { role = "enemy_tank", tags = { "boss" } } }
            )
            local units = build_units(cfg, map)
            local enemy
            for _, u in ipairs(units) do
                if u.tile == "enemy_tank_boss" then enemy = u; break end
            end
            luassert.is_not_nil(enemy)
            luassert.are_equal("boss", enemy.tags[1])
        end)

        it("normal labels have no tags field", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local map = make_battle_map(
                { enemy_infantry = { { x = 1, y = 1 } } },
                { enemy_infantry = { role = "enemy_infantry" } }
            )
            local units = build_units(cfg, map)
            local enemy
            for _, u in ipairs(units) do
                if u.tile == "enemy_infantry" then enemy = u; break end
            end
            luassert.is_nil(enemy.tags)
        end)
    end)
end)
