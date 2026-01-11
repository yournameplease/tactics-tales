local fp = require("src/tactics/util/fp")
local lists = require("src/tactics/util/lists")
local maps = require("src/tactics/util/maps")
local GameData = require("src/tactics/game_data").GameData
local story = require("src/tactics/story/types")
local StoryId = story.StoryId
local StoryDefinition = story.StoryDefinition
local mods = require("src/tactics/mods")
local ModId = mods.ModId
local ModSpec = mods.ModSpec

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
				return nil
			end
			return "mods/" .. mod.path .. "/" .. get_path(mod) .. ".lua"
		end),
		lists.filter(fp.not_nil),
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
				return nil
			end
			return "mods/" .. mod.path .. "/" .. get_path(mod) .. ".lua"
		end),
		lists.filter(fp.not_nil),
		lists.map(function(path: Path): { string: any }
			return pt.include(path) as { string: any }
		end),
		lists.map(function(spec: {string: any}): Value
			return get_data(spec)
		end),
		lists.filter(fp.not_nil)
	)(registered)

	-- get most recently declared value
	return lists.do_reverse(values)[1] or error()
end

function ModLoaderImpl:load_mod_data(): GameData
	local game_data: GameData = {}

	game_data.maps = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.maps end,
		nil
	)
	game_data.battles = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.battles end,
		nil
	)
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
	game_data.characters = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.characters end,
		nil
	)
	game_data.items = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.items end,
		nil
	)

	return game_data
end

return mod_loader
