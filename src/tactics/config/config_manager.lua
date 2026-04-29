---@brief
--- Manages the game's dynamic configuration.
--- Loads user settings and provides default values.

require("profiler")

---@alias DialogueSpeed "very_slow"|"slow"|"normal"|"fast"|"very_fast"|"instant"
---@alias GlyphFamily "keyboard"|"picotron"|"snes"|"nintendo"|"xbox"|"playstation"
---@alias InputGroup "mouse_and_keyboard"|"mouse_only"|"joy_only"

---@class DynamicConfig
---@field log_level? LogLevel
---@field draw_flexbox_debug? boolean
---@field draw_target_debug? boolean
---@field profile? boolean
---@field head_scale? integer
---@field dialogue_speed? DialogueSpeed
---@field glyph_family? GlyphFamily
---@field input_group? InputGroup
---@field demo_mode? boolean
---@field master_volume? integer 0-10
---@field music_volume? integer 0-10
---@field sfx_volume? integer 0-10

---@class ConfigManager
---@field package config DynamicConfig Merged view of user and default config.
---@field package user_config DynamicConfig Overrides stored by the user.
local ConfigManager = {}
ConfigManager.__index = ConfigManager

local DEFAULT_CONFIG = {
	log_level = "DEBUG",
	draw_flexbox_debug = false,
	draw_target_debug = false,
	profile = false,
	head_scale = 1,
	dialogue_speed = "very_fast",
	glyph_family = "keyboard",
	input_group = "mouse_and_keyboard",
	demo_mode = false,
	master_volume = 10,
	music_volume = 5,
	sfx_volume = 10,
}

local config_manager = {}

--- Persist new config to disk and apply profiler settings.
---@param new_config DynamicConfig
function ConfigManager:store_config(new_config)
	-- workaround to ensure demo mode is present
	-- i'd rather require it's editable only via pod,
	-- but the default pod editor doesn't let you add a new field
	new_config.demo_mode = false
	self.user_config = new_config
	store("/appdata/tactics_tales/config.pod", new_config, nil)

	local should_profile = DYNAMIC_CONFIG.profile
	profile.enabled(should_profile, should_profile)
end

--- Reset config to defaults by storing an empty override table.
function ConfigManager:reset_config()
	self:store_config({})
end

--- Poke the system master volume register. volume is 0-10; 0x40 = 100%.
---@param volume integer
function ConfigManager:set_master_volume(volume)
	poke(0x5538, math.floor(volume * 0x40 / 10))
end

--- Poke the system music volume register. volume is 0-10; 0x40 = 100%.
---@param volume integer
function ConfigManager:set_music_volume(volume)
	poke(0x5539, math.floor(volume * 0x40 / 10))
end

--- Poke the system sfx volume register. volume is 0-10; 0x40 = 100%.
---@param volume integer
function ConfigManager:set_sfx_volume(volume)
	poke(0x553a, math.floor(volume * 0x40 / 10))
end

--- Apply glyph family immediately without persisting to disk.
---@param glyph_family GlyphFamily
function ConfigManager:apply_glyph_family(glyph_family)
	self.user_config.glyph_family = glyph_family
end

--- Apply volume settings immediately without persisting to disk.
---@param master_volume integer
---@param music_volume integer
---@param sfx_volume integer
function ConfigManager:apply_volume(master_volume, music_volume, sfx_volume)
	self.user_config.master_volume = master_volume
	self.user_config.music_volume = music_volume
	self.user_config.sfx_volume = sfx_volume
	self:set_master_volume(master_volume)
	self:set_music_volume(music_volume)
	self:set_sfx_volume(sfx_volume)
end

--- Create a new ConfigManager, loading any saved user config from disk.
---@return ConfigManager
function config_manager.new()
	---@type DynamicConfig
	local user_config = fetch("/appdata/tactics_tales/config.pod") --[[@as DynamicConfig]]

	if user_config == nil then
		user_config = {}
	end

	---@type ConfigManager
	local self = setmetatable({}, ConfigManager)

	self.user_config = user_config
	DYNAMIC_CONFIG = setmetatable({}, {
		__index = function(_, k)
			local uc = self.user_config
			local dc = DEFAULT_CONFIG
			if uc[k] then return uc[k] end
			return dc[k]
		end
	})

	self:set_master_volume(DYNAMIC_CONFIG.master_volume)
	self:set_music_volume(DYNAMIC_CONFIG.music_volume)
	self:set_sfx_volume(DYNAMIC_CONFIG.sfx_volume)

	return self
end

return config_manager
