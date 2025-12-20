require("src/tactics/ui/types")

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
