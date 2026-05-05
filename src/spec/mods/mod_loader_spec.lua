local luassert = require("luassert")

local mod_loader = require("src.tactics.mods.mod_loader")

---@class MockDirectory
---@field [string] MockDirectory|any
---@class MockFilesystem
---@field files MockDirectory
local MockFilesystem = {}
MockFilesystem.__index = MockFilesystem

local mock_filesystem = {}

--- Create a MockFilesystem that stubs include and ls.
---@return MockFilesystem
function mock_filesystem.new()
    ---@type MockFilesystem
    local self = setmetatable({
        files = {},
    }, MockFilesystem)

    _G.include = function(path)
        local dir = self.files
        for word in string.gmatch(path, "[%a%.]+/") do
            local next_dir = dir[word]
            if next_dir == nil then
                return nil
            elseif type(next_dir) == "table" then
                dir = next_dir
            else
                return nil
            end
        end
        local file_name = string.gmatch(path, "[%a%.]+$")()
        return dir[file_name]
    end

    _G.ls = function(path)
        local dir = self.files
        for word in string.gmatch(path, "[%a%.]+") do
            local next_dir = dir[word]
            if next_dir == nil then
                return nil
            elseif type(next_dir) == "table" then
                dir = next_dir
            else
                return nil
            end
        end
        local names = {}
        for name, _ in pairs(dir) do
            table.insert(names, name)
        end
        return names
    end

    return self
end

--- Insert a non-Lua directory entry visible to ls() at the given directory path.
--- Uses the same traversal scheme as the ls() stub ([%a%.]+, no slash in keys).
---@param dir_path string Directory path.
---@param filename string Filename to register in that directory.
function MockFilesystem:put_listing_entry(dir_path, filename)
    local dir = self.files
    for word in string.gmatch(dir_path, "[%a%.]+") do
        local next_dir = dir[word]
        if next_dir == nil then
            dir[word] = {}
            next_dir = dir[word]
        end
        dir = next_dir
    end
    dir[filename] = true
end

--- Insert data at the given filesystem path, creating intermediate directories.
---@param path string
---@param data any
function MockFilesystem:put_file(path, data)
    local dir = self.files
    for word in string.gmatch(path, "[%a%.]+/") do
        local next_dir = dir[word]
        if next_dir == nil then
            dir[word] = {}
            next_dir = dir[word]
            dir = next_dir
        elseif type(next_dir) == "table" then
            dir = next_dir
        else
            return
        end
    end
    local file_name = string.gmatch(path, "[%a%.]+$")()
    dir[file_name] = data
end

---@param opts? {default_campaign?: string|false, campaign_select?: string[]|false, gfx?: string[], gfx_files_present?: boolean}
local function make_fs_with_mod(opts)
    opts = opts or {}
    local fs = mock_filesystem.new()
    local content = {
        maps = "game_data/maps",
        missions = "game_data/missions",
        campaigns = "game_data/campaigns",
        characters = "game_data/characters",
        items = "game_data/items",
        skills = "game_data/skills",
    }
    if opts.default_campaign ~= false then
        content.default_campaign = opts.default_campaign or "test_campaign"
    end
    if opts.campaign_select ~= false then
        content.campaign_select = opts.campaign_select or { "test_campaign" }
    end
    if opts.gfx ~= nil then
        content.gfx = opts.gfx
        if opts.gfx_files_present ~= false then
            for _, gfx_path in ipairs(opts.gfx) do
                local dir, fname = gfx_path:match("^(.+)/([^/]+)$")
                if dir then
                    fs:put_listing_entry("mods/test_mod/" .. dir, fname .. ".gfx")
                end
            end
        end
    end
    fs:put_file("mods/test_mod/mod.lua", {
        id = "test_mod",
        name = "Test Mod",
        version = "1.0.0",
        dependencies = {},
        content = content,
    })
    fs:put_file("mods/test_mod/game_data/maps.lua", {})
    fs:put_file("mods/test_mod/game_data/missions.lua", {})
    fs:put_file("mods/test_mod/game_data/campaigns.lua", {
        data = {
            test_campaign = {
                starting_node = "node_1",
                nodes = { node_1 = { { type = "exit_campaign" } } },
            },
            other_campaign = {
                starting_node = "node_1",
                nodes = { node_1 = { { type = "exit_campaign" } } },
            },
        },
    })
    fs:put_file("mods/test_mod/game_data/characters.lua", {})
    fs:put_file("mods/test_mod/game_data/items.lua", {})
    fs:put_file("mods/test_mod/game_data/skills.lua", {})
    return fs
end

local function setup_gfx_globals()
    local cp_calls = {}
    _G.cp = function(src, dst)
        table.insert(cp_calls, { src = src, dst = dst })
    end
    ---@diagnostic disable-next-line: missing-fields
    _G.STATIC_CONFIG = {
        MOD_GFX_SLOT_START = 16,
        MOD_GFX_SLOT_END = 31,
    }
    return cp_calls
end

describe("mod_loader", function()
    before_each(function()
        setup_gfx_globals()
    end)

    describe("load_mod_gfx (via load_mod_data)", function()
        it("skips mods with no gfx field and sets empty gfx_registry", function()
            make_fs_with_mod()
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            local game_data = loader:load_mod_data()

            luassert.are_equal("table", type(game_data.gfx_registry))
            luassert.are_equal(0,
                #(function()
                    local t = {}
                    for k in pairs(game_data.gfx_registry) do t[#t + 1] = k end
                    return t
                end)())
        end)

        it("copies gfx files to correct slot paths and builds gfx_registry", function()
            make_fs_with_mod({ gfx = { "game_data/gfx/tiny_tileset" } })
            local cp_calls = {}
            _G.cp = function(src, dst) table.insert(cp_calls, { src = src, dst = dst }) end
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            local game_data = loader:load_mod_data()

            luassert.are_equal(1, #cp_calls)
            luassert.are_equal("mods/test_mod/game_data/gfx/tiny_tileset.gfx", cp_calls[1].src)
            luassert.are_equal("gfx/16_tiny_tileset.gfx", cp_calls[1].dst)
            luassert.are_equal(16 * 256, game_data.gfx_registry["tiny_tileset"])
        end)

        it("raises an error when more than 16 gfx files are declared", function()
            local gfx_paths = {}
            for i = 1, 17 do
                table.insert(gfx_paths, "game_data/gfx/tileset_" .. i)
            end
            make_fs_with_mod({ gfx = gfx_paths })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            luassert.has_error(function()
                loader:load_mod_data()
            end)
        end)
    end)

    describe("validate_mods", function()
        it("should be valid for a mod with content", function()
            -- Given
            make_fs_with_mod()
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.are_equal(0, #errors, "Got errors:\n\t" .. table.concat(errors, "\n\t"))
        end)

        it("passes validation when declared gfx files are present on disk", function()
            -- Given
            make_fs_with_mod({ gfx = { "game_data/gfx/tiny_tileset" } })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.are_equal(0, #errors, "Got errors:\n\t" .. table.concat(errors, "\n\t"))
        end)

        it("fails validation when a declared gfx file is not present on disk", function()
            -- Given
            make_fs_with_mod({ gfx = { "game_data/gfx/missing_tileset" }, gfx_files_present = false })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_false(is_valid)
            luassert.is_true(#errors > 0)
        end)
    end)

    describe("load_mod_data", function()
        it("defaults campaign_select to all campaign ids when omitted from content", function()
            -- Given
            make_fs_with_mod({ campaign_select = false })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local game_data = loader:load_mod_data()

            -- Then
            luassert.are_equal(2, #game_data.campaigns.campaign_select)
        end)

        it("errors when default_campaign is omitted from all mods' content", function()
            -- Given
            make_fs_with_mod({ default_campaign = false })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- Then
            luassert.has_error(function()
                loader:load_mod_data()
            end)
        end)

        it("populates game_data.skills from a mod's skills file", function()
            -- Given
            local fs = make_fs_with_mod()
            local targeting = {
                get_selection_tiles = function() end,
                get_targets_for_selection = function() end,
                is_target_valid = function() end,
            }
            fs:put_file("mods/test_mod/game_data/skills.lua", {
                heal = {
                    name = "Heal",
                    effect_type = "heal",
                    heal_amount = 3,
                    targeting = targeting,
                },
            })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local game_data = loader:load_mod_data()

            -- Then
            luassert.are_equal("table", type(game_data.skills))
            luassert.are_equal("Heal", game_data.skills.heal.name)
        end)
    end)

    describe("validate_mods (skills)", function()
        local function make_fs_with_skills(skills_data)
            local fs = make_fs_with_mod()
            fs:put_file("mods/test_mod/game_data/skills.lua", skills_data)
            return fs
        end

        local function base_targeting()
            return {
                get_selection_tiles = function() end,
                get_targets_for_selection = function() end,
                is_target_valid = function() end,
            }
        end

        it("passes validation for a valid heal skill", function()
            -- Given
            make_fs_with_skills({
                heal = {
                    name = "Heal",
                    effect_type = "heal",
                    heal_amount = 3,
                    targeting = base_targeting(),
                },
            })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.are_equal(0, #errors, "Got errors:\n\t" .. table.concat(errors, "\n\t"))
        end)

        it("fails validation for an unknown effect_type", function()
            -- Given
            make_fs_with_skills({
                bad_skill = {
                    name = "Bad",
                    effect_type = "explode",
                    targeting = base_targeting(),
                },
            })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, _ = loader:validate_mods()

            -- Then
            luassert.is_false(is_valid)
        end)

        it("fails validation when heal_amount is missing for a heal skill", function()
            -- Given
            make_fs_with_skills({
                broken_heal = {
                    name = "Broken Heal",
                    effect_type = "heal",
                    targeting = base_targeting(),
                },
            })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, _ = loader:validate_mods()

            -- Then
            luassert.is_false(is_valid)
        end)

        it("fails validation when damage is missing for a damage skill", function()
            -- Given
            make_fs_with_skills({
                broken_damage = {
                    name = "Broken Damage",
                    effect_type = "damage",
                    accuracy = 80,
                    targeting = base_targeting(),
                },
            })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, _ = loader:validate_mods()

            -- Then
            luassert.is_false(is_valid)
        end)
    end)
end)
