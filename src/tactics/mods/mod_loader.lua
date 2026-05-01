---@brief
--- Handles loading, sandboxing, and merging of mod data.

local fp = require("src.tactics.util.fp")
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")
local point = require("src.tactics.util.point")
local mod_schema = require("src.tactics.mods.mod_schema")
local schema_validator = require("src.tactics.validator.schema_validator")

---@class RegisteredMod
---@field id string Mod identifier.
---@field path string Filesystem path within mods/ directory.
---@field spec ModSpec The loaded mod specification.

---@class ModLoader Abstract interface for loading and validating mods.
---@field private registered RegisteredMod[] Ordered list of registered mods.
---@field private registered_map table<string, RegisteredMod> Mods indexed by mod ID.
local ModLoader = {}
ModLoader.__index = ModLoader

local mod_loader = {}

--- Create a new ModLoader instance.
---@return ModLoader
function mod_loader.new()
    ---@type ModLoader
    local self = setmetatable({
        registered = {},
        registered_map = {}
    }, ModLoader)
    return self
end

--- Register a mod from the given path (relative to mods/).
---@param path string Local path within the mods/ directory.
function ModLoader:register_mod(path)
    local full_path = "mods/"..path.."/mod.lua"
    ---@type ModSpec
    local mod_spec = include(full_path)

    -- TODO: validate dependencies

    local registered_mod = {
        id = mod_spec.id,
        path = path,
        spec = mod_spec
    }
    table.insert(self.registered, registered_mod)
    self.registered_map[mod_spec.id] = registered_mod

    log.debug("Registered mod "..registered_mod.id.." at "..full_path)
end

--- Stub: validate a single mod by ID (not yet implemented).
---@param id string
---@diagnostic disable-next-line: unused-local
function ModLoader:validate_mod(id)
    self:load_mod_data() -- stub; result intentionally discarded
end

-- todo: will want to only load these files once

--- Load a dictionary of definitions by merging data from all registered mods.
---@param registered RegisteredMod[]
---@param get_path fun(mod: RegisteredMod): string? Returns path relative to mod root (no .lua extension).
---@param get_data? fun(spec: table<string, any>): table<any, any> Extracts the relevant subtable; defaults to returning the whole spec.
---@return table<any, any>
local function load_mod_map(registered, get_path, get_data)
    get_data = get_data or function(spec)
        return spec
    end

    local definitions = fp.pipeline_4(
        lists.map(function(mod)
            if get_path(mod) == nil then
                return ""
            end
            return "mods/" .. mod.path .. "/" .. get_path(mod) .. ".lua"
        end),
        lists.filter(fp.not_empty),
        lists.map(function(path)
            return include(path)
        end),
        lists.map(function(spec)
            return get_data(spec)
        end)
    )(registered)

    return maps.merge(
        table.unpack(definitions)
    )
end


--- Set up the shared sandbox table available to mod scripts as `lib`.
-- TODO: consider safer approaches?
function ModLoader:create_sandbox()
    local sandbox = {
        point = point,
    }
    lib = sandbox -- luacheck: ignore (global set intentionally for mod scripts)

    log.info("Loading mod libraries")
    local libs = {}
    for _,r in ipairs(self.registered) do
        log.info("Loading libraries for "..r.id)
        local base_lib_path = "mods/"..r.path.."/lib"
        local lib_paths = ls(base_lib_path) or {}
        log.debug("Found "..#lib_paths.." libraries at "..base_lib_path)
        for _,lib_path in ipairs(lib_paths) do
            local full_path = base_lib_path.."/"..lib_path
            log.debug("Loading "..full_path)
            local l = include(full_path)
            libs = maps.deep_merge(libs, l)
        end
    end
    log.info("Loaded mod libraries")

    lib.libs = libs
end

--- Load and merge all data from registered mods into a GameData table.
---@return any -- TODO: narrow to GameData once game_data.tl is migrated
function ModLoader:load_mod_data()
    self:create_sandbox()

    local game_data = {} -- TODO: annotate as GameData once game_data.tl is migrated

    game_data.loaded_mods = maps.collect(
        self.registered,
        function(mod)
            return mod.id
        end,
        function(_)
            return true
        end
    )

    log.debug("Loading maps...")
    game_data.maps = load_mod_map(
        self.registered,
        function(mod) return mod.spec.content.maps end,
        nil
    )
    log.debug("Loading battles...")
    game_data.battles = load_mod_map(
        self.registered,
        function(mod) return mod.spec.content.battles end,
        nil
    )
    log.debug("Loading campaigns...")
    local story_data = load_mod_map(
        self.registered,
        function(mod) return mod.spec.content.campaigns end,
        function(spec) return spec.data end
    )

    local campaign_select = nil
    local default_campaign = nil
    for _, mod in ipairs(self.registered) do
        if mod.spec.content.campaign_select ~= nil then
            campaign_select = mod.spec.content.campaign_select
        end
        if mod.spec.content.default_campaign ~= nil then
            default_campaign = mod.spec.content.default_campaign
        end
    end
    if campaign_select == nil then
        campaign_select = {}
        for id in pairs(story_data) do
            table.insert(campaign_select, id)
        end
    end
    if default_campaign == nil then
        error("No default_campaign defined in any mod's content")
    end

    game_data.campaigns = {
        data = story_data,
        default_campaign = default_campaign,
        campaign_select = campaign_select,
    }
    log.debug("Loading characters...")
    game_data.characters = load_mod_map(
        self.registered,
        function(mod) return mod.spec.content.characters end,
        nil
    )
    log.debug("Loading items...")
    game_data.items = load_mod_map(
        self.registered,
        function(mod) return mod.spec.content.items end,
        nil
    )
    log.debug("Finished loading mods.")

    return game_data
end

--- Validate all registered mods against the game data schema.
---@return boolean is_valid, string[] errors
function ModLoader:validate_mods()
    local game_data = self:load_mod_data()

    -- final validation, for all loaded data
    return schema_validator.validate(
        game_data,
        mod_schema.final_schema,
        game_data
    )
end

return mod_loader
