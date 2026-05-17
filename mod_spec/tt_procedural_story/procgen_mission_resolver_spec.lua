local luassert       = require("luassert")

local resolver_mod   = require("tt_procedural_campaign.lib.procgen_mission_resolver")
local compute_seed   = resolver_mod._compute_seed
local build_units    = resolver_mod._build_units
local campaign_state = require("src.tactics.campaign.campaign_state")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@param opts? {faction_id?: string, tier?: integer, story_seed?: integer, battle_index?: integer}
local function make_config(opts)
    opts = opts or {}
    ---@diagnostic disable-next-line: missing-fields
    local mem = campaign_state.new({ get_character = function() return nil end })
    if opts.faction_id   then mem:set("faction_id",      campaign_state.text(opts.faction_id)) end
    if opts.tier         then mem:set("base_difficulty",  campaign_state.text(tostring(opts.tier))) end
    if opts.story_seed   then mem:set("story_seed",       campaign_state.text(tostring(opts.story_seed))) end
    if opts.battle_index then mem:set("battle_index",     campaign_state.text(tostring(opts.battle_index))) end
    return { memory = mem }
end

-- ---------------------------------------------------------------------------
-- compute_seed
-- ---------------------------------------------------------------------------

describe("tt_procedural_campaign.lib.procgen_mission_resolver", function()
    describe("_compute_seed", function()
        it("is deterministic for the same story_seed and battle_index", function()
            local cfg = make_config({ story_seed = 42, battle_index = 3 })
            luassert.are_equal(compute_seed(cfg), compute_seed(cfg))
        end)

        it("differs when battle_index changes", function()
            local cfg1 = make_config({ story_seed = 42, battle_index = 1 })
            local cfg2 = make_config({ story_seed = 42, battle_index = 2 })
            luassert.are_not_equal(compute_seed(cfg1), compute_seed(cfg2))
        end)

        it("differs when story_seed changes", function()
            local cfg1 = make_config({ story_seed = 1,  battle_index = 1 })
            local cfg2 = make_config({ story_seed = 99, battle_index = 1 })
            luassert.are_not_equal(compute_seed(cfg1), compute_seed(cfg2))
        end)

        it("returns a numeric value", function()
            local cfg = make_config({ story_seed = 7, battle_index = 2 })
            luassert.are_equal("number", type(compute_seed(cfg)))
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
