local Box = include "src/ui/box.lua"
local UnitInfo = include "src/ui/panels/unit_info.lua"
local TacticsMap = include "src/ui/panels/tactics_map.lua"
local TextNode = include "src/ui/panels/text_node.lua"

local UIManager = {}

UIManager.THEME = {
    COLOR_DECORATION_PRIMARY = 22,
    COLOR_DECORATION_HIGHLIGHT = 6,
    COLOR_DECORATION_SHADOW = 5,
    COLOR_INTERIOR = 21,
    COLOR_INTERIOR_TEXT = 7,
}

-- Define Layouts
function UIManager:init()
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    local battle_root = Box.new({x=0, y=0, w=480, h=270, dir="row", decoration = "embossed"})

    local battle_summary = Box.new({ x = 0, y = 0, flex_grow = 1, dir = "col", gap = 0 })
    battle_summary:add(TextNode.new({ func = function() return { "BATTLE" }  end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function(state)
        local turn = state.turn_manager.get_turn()
        return { "Turn " .. turn }
    end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function() return { "Defeat all" }  end, justify = "center" }))
    --battle_summary:add(TextNode.new(function() return "hello3"  end, {flex_grow = 1}))

    -- Left Sidebar
    local left = battle_root:add(Box.new({ dir="col", flex_grow = 1, decoration = "recessed" }))
    left:add(battle_summary)
    left:add(UnitInfo.new({ h=100, padding = 0 }))
    --left:add(Box.new({ flex_grow = 1, padding = 0 }))

    battle_root:add(TacticsMap.new(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT, {decoration = "recessed"}))

    self.layouts.BATTLE = battle_root

    -- Set initial
    self.current_layout = self.layouts.BATTLE
end

function UIManager:draw(global_state)
    LOG.info("DRAWING")
    -- Recalculate size and positions
    self.current_layout:measure()
    self.current_layout:layout()

    -- Render
    self.current_layout:draw(global_state)
end

return UIManager