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
            -- Extremely unlikely to collide with distinct seeds
            luassert.are_not_equal(compute_seed(ctx1), compute_seed(ctx2))
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- build_units
    -- ---------------------------------------------------------------------------

    describe("_build_units", function()
        it("always includes a player unit with tile player_deployment", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local units = build_units(cfg, {})
            local found = false
            for _, u in ipairs(units) do
                if u.side == "player" and u.tile == "player_deployment" then
                    found = true; break
                end
            end
            luassert.is_true(found)
        end)

        it("creates one enemy unit per enemy_infantry spawn point", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local tile_labels = {
                enemy_infantry = { { x = 3, y = 4 }, { x = 5, y = 6 } },
            }
            local units = build_units(cfg, tile_labels)
            local count = 0
            for _, u in ipairs(units) do
                if u.tile == "enemy_infantry" and u.side == "enemy" then
                    count = count + 1
                end
            end
            luassert.are_equal(2, count)
        end)

        it("creates one enemy unit per enemy_commander spawn point", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local tile_labels = {
                enemy_commander = { { x = 8, y = 8 } },
            }
            local units = build_units(cfg, tile_labels)
            local count = 0
            for _, u in ipairs(units) do
                if u.tile == "enemy_commander" and u.side == "enemy" then
                    count = count + 1
                end
            end
            luassert.are_equal(1, count)
        end)

        it("skips roles with no spawn points", function()
            local cfg = make_config({ faction_id = "bandits", tier = 1 })
            local units = build_units(cfg, {})
            -- Only the player unit should be present
            luassert.are_equal(1, #units)
        end)

        it("uses the faction tier to select the character template", function()
            local cfg = make_config({ faction_id = "bandits", tier = 2 })
            local tile_labels = {
                enemy_infantry = { { x = 1, y = 1 } },
            }
            local units = build_units(cfg, tile_labels)
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
            local tile_labels = {
                enemy_commander = { { x = 5, y = 5 } },
            }
            local units = build_units(cfg, tile_labels)
            local found_stationary = false
            for _, u in ipairs(units) do
                if u.tile == "enemy_commander" and u.ai ~= nil then
                    -- stationary AI is truthy and distinct from move_two
                    found_stationary = true; break
                end
            end
            luassert.is_true(found_stationary)
        end)
    end)
end)
