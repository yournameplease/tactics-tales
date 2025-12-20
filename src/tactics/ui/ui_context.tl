require("src/tactics/ui/types")

local enum UIContextType
	"battle"
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
