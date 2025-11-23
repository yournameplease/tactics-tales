local Box = include "src/ui/box.lua"
local UnitInfo = include "src/ui/panels/unit_info.lua"

local UIManager = {}

UIManager.THEME = {
    COLOR_DECORATION_PRIMARY = 22,
    COLOR_DECORATION_HIGHLIGHT = 6,
    COLOR_DECORATION_SHADOW = 5,
    COLOR_INTERIOR = 21
}

local BATTLE_WIDTH = CONFIG.MAP_WIDTH * CONFIG.TILE_WIDTH + 2
local BATTLE_HEIGHT = CONFIG.MAP_HEIGHT * CONFIG.TILE_HEIGHT + 2

-- Define Layouts
function UIManager:init()
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    local battle_root = Box.new({x=0, y=0, w=480, h=270, dir="row", decoration = "embossed"})

    -- Left Sidebar
    local left = battle_root:add(Box.new({ dir="col", flex_grow = 1, decoration = "recessed" }))
    left:add(UnitInfo.new({ h=100, padding = 0 }))
    left:add(Box.new({ flex_grow = 1, padding = 0 }))

    battle_root:add(Box.new({w=BATTLE_WIDTH, h=BATTLE_HEIGHT, decoration = "recessed"}))

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