require("src/tactics/ui/types")
local UILayoutId = require("src/tactics/ui/types").UILayoutId
local InputLabel = require("src/tactics/joypad").InputLabel

local enum UIContextType
	"battle"
	"story"
	"game"
end

local interface UIContext
	type: UIContextType

    input_actions: {InputLabel: string}
	layout: UILayoutId
end

local ui_context = {
	UIContextType = UIContextType,
	UIContext = UIContext
}

return ui_context
