---@brief
--- Manages the game's dynamic configuration.
--- Loads user settings and provides default values.

require("profiler")

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
	dialogue_speed = "normal",
	glyph_family = "keyboard",
}

local config_manager = {}

--- Persist new config to disk and apply profiler settings.
---@param new_config DynamicConfig
function ConfigManager:store_config(new_config)
	self.user_config = new_config
	pt.store("/appdata/tactics_tales/config.pod", new_config, nil)

	local should_profile = DYNAMIC_CONFIG.profile
	profile.enabled(should_profile, should_profile)
end

--- Reset config to defaults by storing an empty override table.
function ConfigManager:reset_config()
	self:store_config({})
end

--- Create a new ConfigManager, loading any saved user config from disk.
---@return ConfigManager
function config_manager.new()
	---@type DynamicConfig
	local user_config = pt.fetch("/appdata/tactics_tales/config.pod") --[[@as DynamicConfig]]

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

	return self
end

return config_manager
