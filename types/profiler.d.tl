
local record Profile
	draw: function()
	enabled: function(boolean, boolean)
	metamethod __call: function(Profile, name: string, linger?: boolean)
end

global type profile = Profile
