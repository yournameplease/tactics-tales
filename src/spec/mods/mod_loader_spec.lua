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


---@param opts? {default_story?: string|false, story_select?: string[]|false}
local function make_fs_with_mod(opts)
    opts = opts or {}
    local fs = mock_filesystem.new()
    local content = {
        maps = "game_data/maps",
        battles = "game_data/battles",
        stories = "game_data/stories",
        characters = "game_data/characters",
        items = "game_data/items",
    }
    if opts.default_story ~= false then
        content.default_story = opts.default_story or "test_story"
    end
    if opts.story_select ~= false then
        content.story_select = opts.story_select or {"test_story"}
    end
    fs:put_file("mods/test_mod/mod.lua", {
        id = "test_mod",
        name = "Test Mod",
        version = "1.0.0",
        dependencies = {},
        content = content,
    })
    fs:put_file("mods/test_mod/game_data/maps.lua", {})
    fs:put_file("mods/test_mod/game_data/battles.lua", {})
    fs:put_file("mods/test_mod/game_data/stories.lua", {
        data = {
            test_story = {
                starting_node = "node_1",
                nodes = { node_1 = {{type = "exit_story"}} },
            },
            other_story = {
                starting_node = "node_1",
                nodes = { node_1 = {{type = "exit_story"}} },
            },
        },
    })
    fs:put_file("mods/test_mod/game_data/characters.lua", {})
    fs:put_file("mods/test_mod/game_data/items.lua", {})
    return fs
end

describe("mod_loader", function()
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
            luassert.are_equal(0, #errors, "Got errors:\n\t"..table.concat(errors, "\n\t"))
        end)
    end)

    describe("load_mod_data", function()
        it("defaults story_select to all story ids when omitted from content", function()
            -- Given
            make_fs_with_mod({ story_select = false })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local game_data = loader:load_mod_data()

            -- Then
            luassert.are_equal(2, #game_data.stories.story_select)
        end)

        it("errors when default_story is omitted from all mods' content", function()
            -- Given
            make_fs_with_mod({ default_story = false })
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- Then
            luassert.has_error(function()
                loader:load_mod_data()
            end)
        end)
    end)
end)
