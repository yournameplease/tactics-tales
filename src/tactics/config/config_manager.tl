---@brief
--- Manages the game's dynamic configuration.
--- Loads user settings and provides default values.

require("profiler")

local DEFAULT_CONFIG: DynamicConfig = {
	log_level = "DEBUG",
	draw_flexbox_debug = false,
	draw_target_debug = false,
	profile = false,
	head_scale = 1,
	dialogue_speed = "normal",
}

local interface ConfigManager
	store_config: function(self, DynamicConfig)
	reset_config: function(self)
	config: DynamicConfig
end

local config_manager = {
	ConfigManager = ConfigManager
}

local record ConfigManagerImpl
	is ConfigManager
	user_config: DynamicConfig
end

function ConfigManagerImpl:store_config(new_config: DynamicConfig)
	self.user_config = new_config
	pt.store("/appdata/tactics_tales/config.pod", new_config, nil)
	
    local should_profile = DYNAMIC_CONFIG.profile
    profile.enabled(should_profile, should_profile)
end

function ConfigManagerImpl:reset_config()
	self:store_config({})
end

function config_manager.new(): ConfigManager
	local user_config: DynamicConfig = pt.fetch("/appdata/tactics_tales/config.pod") as DynamicConfig

	if user_config == nil then
		user_config = {}
	end

	local self: ConfigManagerImpl = setmetatable({},{
		__index = ConfigManagerImpl
	})

	self.user_config = user_config
	DYNAMIC_CONFIG = setmetatable({},{
		__index = function(_t: {any: string}, k: string): any
			local uc = self.user_config as {string: any}
			local dc = DEFAULT_CONFIG as {string: any}
			if uc[k] then return uc[k] end
			return dc[k]
		end
	})

	return self
end

return config_manager
