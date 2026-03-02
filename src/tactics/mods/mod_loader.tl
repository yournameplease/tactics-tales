---@brief
--- Handles loading, sandboxing, and merging of mod data.

local fp = require("src.tactics.util.fp")
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")
local point = require("src.tactics.util.point")
local GameData = require("src.tactics.game_data").GameData
local story = require("src.tactics.story.types")
local StoryId = story.StoryId
local StoryDefinition = story.StoryDefinition
local mods = require("src.tactics.mods")
local ModId = mods.ModId
local ModSpec = mods.ModSpec
local mod_schema = require("src.tactics.mods.mod_schema")
local schema_validator = require("src.tactics.validator.schema_validator")

local record RegisteredMod
	id: ModId
	path: Path
	spec: ModSpec
end

-- some of this is hastily schema'd just to get this working
-- read up on good approaches later on
local interface ModLoader
	register_mod: function(self, path: string)
	load_mod_data: function(self): GameData
	-- returns is_valid, {errors}
	validate_mods: function(self): boolean, {string}
end

local mod_loader = {
	ModId = ModId,
	ModLoader = ModLoader
}

local record ModLoaderImpl
	is ModLoader

	registered: { RegisteredMod }
	registered_map: { ModId: RegisteredMod }
end

function mod_loader.new(): ModLoader
	local self: ModLoaderImpl = setmetatable({
		registered = {},
		registered_map = {}
	}, { __index = ModLoaderImpl })

	return self
end

function ModLoaderImpl:register_mod(path: string)
	local full_path = "mods/"..path.."/mod.lua"
	local mod_spec: ModSpec = pt.include(full_path) as ModSpec

	-- TODO: validate dependencies

	local registered_mod = {
		id = mod_spec.id,
		path = path,
		spec = mod_spec
	}
	pt.add(self.registered, registered_mod)
	self.registered_map[mod_spec.id] = registered_mod

	log.debug("Registered mod "..registered_mod.id.." at "..full_path)
end

function ModLoaderImpl:validate_mod(id: ModId)
	local data = self:load_mod_data()
	
end

-- todo: will want to only load these files once

local function load_mod_map<Key, Definition>(
	registered: {RegisteredMod},
	get_path: function(RegisteredMod): Path, --local path, nillable
	get_data: function(spec: {string: any}): {Key: Definition}
): {Key: Definition}
	get_data =
		get_data or 
		function(spec: {string: any}): {Key: Definition}
			return spec as {Key: Definition}
		end

	local definitions: {{Key: Definition}} = fp.pipeline_4(
		lists.map(function(mod: RegisteredMod): Path
			if get_path(mod) == nil then
				return ""
			end
			return "mods/" .. mod.path .. "/" .. get_path(mod) .. ".lua"
		end),
		lists.filter(fp.not_empty),
		lists.map(function(path: Path): { string: any }
			return pt.include(path) as { string: any }
		end),
		lists.map(function(spec: {string: any}): { Key: Definition }
			return get_data(spec)
		end)
	)(registered)

	return maps.merge(
		table.unpack(definitions)
	)	
end

local function load_mod_val<Value>(
	registered: {RegisteredMod},
	get_path: function(RegisteredMod): Path, --local path, nillable
	get_data: function(spec: {string: any}): Value
): Value
	get_data =
		get_data or 
		function(spec: {string: any}): Value
			return spec as Value
		end

	local values: {Value} = fp.pipeline_5(
		lists.map(function(mod: RegisteredMod): Path
			if get_path(mod) == nil then
				return ""
			end
			return "mods/" .. mod.path .. "/" .. get_path(mod) .. ".lua"
		end),
		lists.filter(fp.not_empty),
		lists.map(function(path: Path): { string: any }
			log.debug("Including "..path)
			return pt.include(path) as { string: any }
		end),
		lists.map(function(spec: {string: any}): Value
			return get_data(spec)
		end),
		lists.filter(fp.not_nil)
	)(registered)

	-- get most recently declared value
	return lists.do_reverse(values)[1] or error("No mod data found for a value.")
end

-- TODO: consider safer approaches?
function ModLoaderImpl:create_sandbox(): {string: any}
	local sandbox: {string: any} = {
		point = point,
	}
	lib = sandbox

	log.info("Loading mod libraries")
	local libs: {string: any} = {}
	for _,r in ipairs(self.registered) do
		log.info("Loading libraries for "..r.id)
		local base_lib_path = "mods/"..r.path.."/lib"
		local lib_paths = pt.ls(base_lib_path) or {}
		log.debug("Found "..#lib_paths.." libraries at "..base_lib_path)
		for _,lib_path in ipairs(lib_paths) do
			local full_path = base_lib_path.."/"..lib_path
			log.debug("Loading "..full_path)
			local l = pt.include(full_path) as {string: any}
			libs = maps.deep_merge(libs, l)
		end
	end
	log.info("Loaded mod libraries")

	lib.libs = libs
end

function ModLoaderImpl:load_mod_data(): GameData
	self:create_sandbox()

	local game_data: GameData = {}

	game_data.loaded_mods = maps.collect(
		self.registered,
		function(mod: RegisteredMod): string
			return mod.id
		end,
		function(_: RegisteredMod): boolean
			return true
		end
	)

	log.debug("Loading maps...")
	game_data.maps = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.maps end,
		nil
	)
	log.debug("Loading battles...")
	game_data.battles = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.battles end,
		nil
	)
	log.debug("Loading stories...")
	game_data.stories = {
		data = load_mod_map(
			self.registered,
			function(mod: RegisteredMod): Path return mod.spec.content.stories end,
			function(spec: {string: any}): {StoryId: StoryDefinition}
				return spec.data as {StoryId: StoryDefinition}
			end
		),
		default_story = load_mod_val(
			self.registered,
			function(mod: RegisteredMod): Path return mod.spec.content.stories end,
			function(spec: {string: any}): StoryId
				return spec.default_story as StoryId
			end
		),
		story_select = load_mod_val(
			self.registered,
			function(mod: RegisteredMod): Path return mod.spec.content.stories end,
			function(spec: {string: any}): {StoryId}
				return spec.story_select as {StoryId}
			end
		)
	}
	log.debug("Loading characters...")
	game_data.characters = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.characters end,
		nil
	)
	log.debug("Loading items...")
	game_data.items = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.items end,
		nil
	)
	log.debug("Finished loading mods.")

	return game_data
end


function ModLoaderImpl:validate_mods(): boolean, {string}
	local game_data = self:load_mod_data()

	-- final validation, for all loaded data	
	return schema_validator.validate(
		game_data,
		mod_schema.final_schema,
		game_data
	)
end

return mod_loader
