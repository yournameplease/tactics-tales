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
            skill_defs = opts.skill_defs or {},
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
                skill_states = opts.skill_states or {},
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

-- ---------------------------------------------------------------------------
-- SELECT_SKILL helpers
-- ---------------------------------------------------------------------------

local function make_skill_def(overrides)
    local def = {
        name = overrides.name or "Test Skill",
        uses_per_battle = overrides.uses_per_battle,
        cooldown = overrides.cooldown,
        targeting = {
            get_selection_tiles = overrides.get_selection_tiles or function() return { {} } end,
        },
    }
    return def
end

local function get_select_skill_options(services, ctx)
    local bus = event_bus.new()
    local manager = battle_menu_manager.new(services, bus)
    local step_def = manager.menu_definitions["MENU_PLAYER_TURN"].steps["SELECT_SKILL"]
    return step_def.node.get_children(services, ctx)
end

local function get_select_skill_step(services)
    local bus = event_bus.new()
    local manager = battle_menu_manager.new(services, bus)
    return manager.menu_definitions["MENU_PLAYER_TURN"].steps["SELECT_SKILL"]
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("battle.battle_menu_manager SELECT_SKILL", function()
    it("available skill navigates to SELECT_SKILL_TARGET", function()
        local def = make_skill_def({ name = "Heal" })
        local services = make_mock_services({ skill_defs = { heal = def } })
        local ctx = make_mock_ctx({
            skill_loadout = { "heal" },
            skill_states = { heal = { cooldown_remaining = 0, uses_remaining = nil } },
        })
        local options = get_select_skill_options(services, ctx)
        luassert.are_equal(1, #options)
        local opt = options[1]
        luassert.are_equal("heal", opt.id)
        luassert.are_equal("Heal", opt.text)
        luassert.are_equal("SELECT_SKILL_TARGET", opt.next_state)
    end)

    it("skill on cooldown is greyed with CD:N", function()
        local def = make_skill_def({ name = "Fireball", cooldown = 3 })
        local services = make_mock_services({ skill_defs = { fireball = def } })
        local ctx = make_mock_ctx({
            skill_loadout = { "fireball" },
            skill_states = { fireball = { cooldown_remaining = 2, uses_remaining = nil } },
        })
        local options = get_select_skill_options(services, ctx)
        luassert.are_equal(1, #options)
        local opt = options[1]
        luassert.are_equal("Fireball  CD:2", opt.text)
        luassert.is_nil(opt.next_state)
    end)

    it("skill with uses exhausted is greyed with 0/N", function()
        local def = make_skill_def({ name = "War Cry", uses_per_battle = 3 })
        local services = make_mock_services({ skill_defs = { war_cry = def } })
        local ctx = make_mock_ctx({
            skill_loadout = { "war_cry" },
            skill_states = { war_cry = { cooldown_remaining = 0, uses_remaining = 0 } },
        })
        local options = get_select_skill_options(services, ctx)
        luassert.are_equal(1, #options)
        local opt = options[1]
        luassert.are_equal("War Cry  0/3", opt.text)
        luassert.is_nil(opt.next_state)
    end)

    it("skill with no valid targets is greyed with 'no targets'", function()
        local def = make_skill_def({
            name = "Heal",
            get_selection_tiles = function() return {} end,
        })
        local services = make_mock_services({ skill_defs = { heal = def } })
        local ctx = make_mock_ctx({
            skill_loadout = { "heal" },
            skill_states = { heal = { cooldown_remaining = 0, uses_remaining = nil } },
        })
        local options = get_select_skill_options(services, ctx)
        luassert.are_equal(1, #options)
        local opt = options[1]
        luassert.are_equal("Heal  no targets", opt.text)
        luassert.is_nil(opt.next_state)
    end)

    it("back from SELECT_SKILL returns to SELECT_ACTION", function()
        local services = make_mock_services()
        local step = get_select_skill_step(services)
        luassert.are_equal("SELECT_ACTION", step.previous_step)
    end)

    it("skills with missing def are silently skipped", function()
        local services = make_mock_services({ skill_defs = {} })
        local ctx = make_mock_ctx({
            skill_loadout = { "unknown_skill" },
            skill_states = {},
        })
        local options = get_select_skill_options(services, ctx)
        luassert.are_equal(0, #options)
    end)

    it("uses check takes priority over cooldown", function()
        local def = make_skill_def({ name = "Combo", uses_per_battle = 1, cooldown = 2 })
        local services = make_mock_services({ skill_defs = { combo = def } })
        local ctx = make_mock_ctx({
            skill_loadout = { "combo" },
            skill_states = { combo = { cooldown_remaining = 2, uses_remaining = 0 } },
        })
        local options = get_select_skill_options(services, ctx)
        luassert.are_equal("Combo  0/1", options[1].text)
    end)
end)
