local type _ = require("busted")
local luassert = require("luassert")
require("spec.picotron_shim")
require("spec.require_trimmer")

local mod_loader = require("src.tactics.mods.mod_loader")

local type MockDirectory = { string: MockDirectory | any }

local record MockFilesystem
    files: MockDirectory
    
    add_file: function(self, path: string, data: any)
end

local mock_filesystem = {}

function mock_filesystem.new(): MockFilesystem
    local self: MockFilesystem = setmetatable({
        files = {},
    },{
        __index = MockFilesystem
    })
    pt.include = function(path: string): any
        local dir = self.files
        for word in string.gmatch(path, "[%a%.]+/") do
            local next_dir = dir[word]
            if next_dir == nil then
                -- mock the picotron error?
                return nil
            elseif next_dir is MockDirectory then
                dir = next_dir
            else
                -- error, found a file instead of directory
                return nil
            end
        end
        local file_name = string.gmatch(path, "[%a%.]+$")()
        return dir[file_name]
    end
    pt.ls = function(path: string): any
        local dir = self.files
        for word in string.gmatch(path, "[%a%.]+") do
            local next_dir = dir[word]
            if next_dir == nil then
                -- mock the picotron error?
                return nil
            elseif next_dir is MockDirectory then
                dir = next_dir
            else
                -- error, found a file instead of directory
                return nil
            end
        end

        local names = {}
        for name,_ in pairs(dir) do
            table.insert(names,name)
        end
        return names
    end
    return self
end

function MockFilesystem:add_file(path: string, data: any)
    local dir = self.files
    for word in string.gmatch(path, "[%a%.]+/") do
        local next_dir = dir[word]
        if next_dir == nil then
            -- mock the picotron error?
            dir[word] = {}
            next_dir = dir[word]
            assert(next_dir is MockDirectory)
            dir = next_dir
        elseif next_dir is MockDirectory then
            dir = next_dir
        else
            -- error, found a file instead of directory
            return
        end
    end
    local file_name = string.gmatch(path, "[%a%.]+$")()
    dir[file_name] = data
end


describe("mod_loader", function()
    describe("validate_mods", function()
        it("should be valid for a mod with no content", function()
            -- Given
            local fs = mock_filesystem.new()
            fs:add_file("mods/test_mod/mod.lua", {
                id = "test_mod",
                name = "Test Mod",
                version = "1.0.0",
                dependencies = {},
                content = {},
            })
            
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors)
        end)
    end)
end)
