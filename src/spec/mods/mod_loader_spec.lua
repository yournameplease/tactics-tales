local luassert = require("luassert")

local mod_loader = require("src.tactics.mods.mod_loader")

---@class MockDirectory
---@field [string] MockDirectory|any
---@class MockFilesystem
---@field files MockDirectory
local MockFilesystem = {}
MockFilesystem.__index = MockFilesystem

local mock_filesystem = {}

--- Create a MockFilesystem that stubs pt.include and pt.ls.
---@return MockFilesystem
function mock_filesystem.new()
    ---@type MockFilesystem
    local self = setmetatable({
        files = {},
    }, MockFilesystem)

    pt.include = function(path)
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

    pt.ls = function(path)
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


describe("mod_loader", function()
    describe("validate_mods", function()
        it("should be valid for a mod with content", function()
            -- Given
            local fs = mock_filesystem.new()
            fs:put_file("mods/test_mod/mod.lua", {
                id = "test_mod",
                name = "Test Mod",
                version = "1.0.0",
                dependencies = {},
                content = {
                    maps = "game_data/maps",
                    battles = "game_data/battles",
                    stories = "game_data/stories",
                    characters = "game_data/characters",
                    items = "game_data/items",
                }
            })
            fs:put_file("mods/test_mod/game_data/maps.lua", {
            })
            fs:put_file("mods/test_mod/game_data/battles.lua", {
            })
            fs:put_file("mods/test_mod/game_data/stories.lua", {
                data = {
                    test_story = {
                        starting_node = 'node_1',
                        nodes = {
                            node_1 = {{type = 'exit_story'}}
                        }
                    }
                },
                default_story = "test_story",
                story_select = {"test_story"},
            })
            fs:put_file("mods/test_mod/game_data/characters.lua", {
            })
            fs:put_file("mods/test_mod/game_data/items.lua", {
            })

            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors, "Got errors:\n\t"..table.concat(errors, "\n\t"))
        end)
    end)
end)
