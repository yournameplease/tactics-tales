local Box = include "src/ui/box.lua"
local UnitInfo = include "src/ui/panels/unit_info.lua"

local UIManager = {}

UIManager.THEME = {
    COLOR_DECORATION_PRIMARY = 22,
    COLOR_DECORATION_HIGHLIGHT = 6,
    COLOR_DECORATION_SHADOW = 5,
    COLOR_INTERIOR = 21
}

-- Define Layouts
function UIManager:init()
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    local battle_root = Box.new({x=0, y=0, w=480, h=270, dir="row", decoration = "embossed"})

    -- Left Sidebar
    local left = battle_root:add(Box.new({ w=120, h=270, dir="col", gap=5, decoration = "recessed" }))
    left:add(UnitInfo.new({ w=120, h=100, bg_color=5})) -- Top right
    left:add(Box.new({ w=120, h=165, bg_color=2}))      -- Bottom right (Log)

    battle_root:add(Box.new({w=300, h=270, decoration = "recessed"}))

    self.layouts.BATTLE = battle_root

    -- Set initial
    self.current_layout = self.layouts.BATTLE
end

function UIManager:draw(global_state)
    -- Recalculate positions (in case of dynamic resizing or initial setup)
    self.current_layout:layout()

    -- Render
    self.current_layout:draw(global_state)
end

return UIManager