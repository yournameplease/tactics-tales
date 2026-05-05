local luassert = require("luassert")
local battle_menu_manager = require("src.tactics.battle.battle_menu_manager")
local event_bus = require("src.tactics.systems.event_bus")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function make_mock_battle_map()
    return {
        width = 10,
        height = 10,
        get_targets_in_range = function() return {} end,
        get_nearby_interactions = function() return {} end,
        get_at_tile = function() return nil end,
    }
end

local function make_mock_services(opts)
    opts = opts or {}
    local map = opts.battle_map or make_mock_battle_map()
    return {
        battle_map = map,
        tutorial_mode = opts.tutorial_mode or false,
        tactics_engine = {
            active_point = { x = 0, y = 0 },
            get_valid_tiles_for_unit = function()
                return { get = function() return nil end }
            end,
        },
    }
end

local function make_mock_ctx(opts)
    opts = opts or {}
    return {
        acting_unit = {
            unit = {
                character = {
                    skill_loadout = opts.skill_loadout or {},
                    get_weapon_targeting = function()
                        return { is_target_valid = function() return false end }
                    end,
                },
                stats = { movement = 3 },
                tile = { x = 0, y = 0, copy = function(self) return { x = self.x, y = self.y } end },
            },
            point = { x = 0, y = 0, copy = function(self) return { x = self.x, y = self.y } end },
        },
        destination = { point = { x = 0, y = 0 } },
    }
end

local function get_select_action_options(services, ctx)
    local bus = event_bus.new()
    local manager = battle_menu_manager.new(services, bus)
    local step_def = manager.menu_definitions["MENU_PLAYER_TURN"].steps["SELECT_ACTION"]
    return step_def.node.get_children(services, ctx)
end

local function has_option(options, id)
    for _, opt in ipairs(options) do
        if opt.id == id then return true end
    end
    return false
end

local function find_option(options, id)
    for _, opt in ipairs(options) do
        if opt.id == id then return opt end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("battle.battle_menu_manager SELECT_ACTION", function()
    it("shows Skills option when unit has skills", function()
        local services = make_mock_services()
        local ctx = make_mock_ctx({ skill_loadout = { "heal" } })
        local options = get_select_action_options(services, ctx)
        luassert.is_true(has_option(options, "skills"))
    end)

    it("hides Skills option when unit has no skills", function()
        local services = make_mock_services()
        local ctx = make_mock_ctx({ skill_loadout = {} })
        local options = get_select_action_options(services, ctx)
        luassert.is_false(has_option(options, "skills"))
    end)

    it("Skills option navigates to SELECT_SKILL", function()
        local services = make_mock_services()
        local ctx = make_mock_ctx({ skill_loadout = { "fireball" } })
        local options = get_select_action_options(services, ctx)
        local skills_opt = find_option(options, "skills")
        luassert.is_not_nil(skills_opt)
        luassert.are_equal("SELECT_SKILL", skills_opt.next_state)
    end)

    it("Attack option is present with target in range regardless of skill loadout", function()
        local map = make_mock_battle_map()
        map.get_targets_in_range = function() return { {} } end
        local services = make_mock_services({ battle_map = map })

        local ctx_with = make_mock_ctx({ skill_loadout = { "heal" } })
        luassert.is_true(has_option(get_select_action_options(services, ctx_with), "attack"))

        local ctx_without = make_mock_ctx({ skill_loadout = {} })
        luassert.is_true(has_option(get_select_action_options(services, ctx_without), "attack"))
    end)

    it("Wait option is present regardless of skill loadout", function()
        local services = make_mock_services()

        local ctx_with = make_mock_ctx({ skill_loadout = { "heal" } })
        luassert.is_true(has_option(get_select_action_options(services, ctx_with), "wait"))

        local ctx_without = make_mock_ctx({ skill_loadout = {} })
        luassert.is_true(has_option(get_select_action_options(services, ctx_without), "wait"))
    end)
end)
