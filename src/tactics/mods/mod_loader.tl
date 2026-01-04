local fp = require("src/tactics/util/fp")
local lists = require("src/tactics/util/lists")
local maps = require("src/tactics/util/maps")
local GameData = require("src/tactics/game_data").GameData
local MapDefinition = require("src/tactics/battle/map/types").MapDefinition
local BattleDefinition = require("src/tactics/battle/definition").BattleDefinition
local story = require("src/tactics/story/types")
local StoryId = story.StoryId
local StoryDefinition = story.StoryDefinition
-- local MapDefinition = require("src/tactics/battle/map/types").MapDefinition
local ItemDefinition = require("src/tactics/types/item_definition").ItemDefinition
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
		
	}, { __index = ModLoaderImpl })

	return self
end

function ModLoaderImpl:register_mod(path: string)
	local full_path = "mods/"..path
	local modspec: ModSpec = pt.include(full_path) as ModSpec

	
end

function ModLoaderImpl:validate_mod(id: ModId)
	local data = self:load_mod_data()

	
end

local function load_mod_map<Key, Definition>(
	registered: {RegisteredMod},
	get_path: function(RegisteredMod): Path --local path, nillable
): {Key: Definition}
	local definitions: {{Key: Definition}} = fp.pipeline_3(
		lists.map(function(mod: RegisteredMod): Path
			if get_path(mod) == nil then
				return nil
			end
			return "mods/" .. mod.path .. "/" .. get_path(mod) .. ".lua"
		end),
		lists.filter(fp.not_nil),
		lists.map(function(path: Path): { Key: Definition }
			return pt.include(path) as { Key: Definition }
		end)
	)(registered)

	return maps.merge(
		table.unpack(definitions)
	)	
end

function ModLoaderImpl:load_mod_data(): GameData
	local game_data: GameData = {}

	game_data.maps = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.maps end
	)
	game_data.battles = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.battles end
	)
	game_data.stories = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.stories end
	)
	-- game_data.characters = load_mod_map(
	-- 	self.registered,
	-- 	function(mod: RegisteredMod): Path return mod.spec.content.characters end
	-- )
	game_data.items = load_mod_map(
		self.registered,
		function(mod: RegisteredMod): Path return mod.spec.content.items end
	)

	return game_data
end
