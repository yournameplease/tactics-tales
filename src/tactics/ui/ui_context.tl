require("src/tactics/ui/types")
local UILayoutId = require("src/tactics/ui/types").UILayoutId

local enum UIContextType
	"battle"
	"story"
	"game"
end

local interface UIContext
	type: UIContextType
	layout: UILayoutId
end

local ui_context = {
	UIContextType = UIContextType,
	UIContext = UIContext
}

return ui_context
