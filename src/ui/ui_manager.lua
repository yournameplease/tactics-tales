local Box = include "src/ui/box.lua"
local UnitInfo = include "src/ui/panels/unit_info.lua"

local UIManager = {}

UIManager.THEME = {
    bg = 0,
    border = 6,
    padding = 4
}

-- Define Layouts
function UIManager:init()
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    local battle_root = Box.new({x=0, y=0, w=480, h=270, dir="row"})

    -- Left Sidebar (Info + Log)
    local right_col = battle_root:add(Box.new({w=120, h=270, dir="col", gap=5}))
    right_col:add(UnitInfo.new({w=120, h=100, bg_color=5})) -- Top right
    right_col:add(Box.new({w=120, h=165, bg_color=2}))      -- Bottom right (Log)

    -- Center Area (The Map Viewport - usually transparent so we see the game)
    battle_root:add(Box.new({w=300, h=270}))

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