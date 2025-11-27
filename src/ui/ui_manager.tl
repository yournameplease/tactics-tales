local Box = require("src/ui/box.lua")
local UnitInfo = require("src/ui/panels/unit_info.lua")
local CombatPreview = require("src/ui/panels/combat_preview.lua")
local TacticsMap = require("src/ui/panels/tactics_map.lua")
local TextNode = require("src/ui/panels/text_node.lua")
local EventMessageLog = require("src/ui/panels/event_message_log.lua")

local MenuValidator = require("src/ui/validator.lua")

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

    local battle_summary = Box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0 })
    battle_summary:add(TextNode.new({ func = function() return { "BATTLE" }  end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function(state)
        local turn = state.turn_manager.get_turn()
        return { "Turn " .. turn }
    end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function() return { "Defeat all" }  end, justify = "center" }))
    do
        local battle_root = Box.new({x=0, y=0, w=480, h=270, dir="row", decoration = "embossed"})

        -- Left Sidebar
        local left = battle_root:add(Box.new({ dir="col", flex_grow = 1, decoration = "recessed" }))
        left:add(battle_summary)
        left:add(UnitInfo.new({ padding = 0 }))
        left:add(EventMessageLog.new({ flex_grow = 1}))

        battle_root:add(TacticsMap.new(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT, {decoration = "recessed"}))

        self.layouts.TACTICS = battle_root
    end
    do
        local battle_root = Box.new({x=0, y=0, w=480, h=270, dir="row", decoration = "embossed"})

        -- Left Sidebar
        local left = battle_root:add(Box.new({ dir="col", flex_grow = 1, decoration = "recessed" }))
        left:add(battle_summary)
        left:add(CombatPreview.new({ padding = 0 }))
        left:add(EventMessageLog.new({ flex_grow = 1}))
        --left:add(Box.new({ flex_grow = 1, padding = 0 }))

        battle_root:add(TacticsMap.new(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT, {decoration = "recessed"}))

        self.layouts.COMBAT_PREVIEW = battle_root
    end

    -- Validate all layouts
    for i, v in pairs(self.layouts) do
        MenuValidator.validate(v)
    end

    -- Set initial
    self.current_layout = self.layouts.TACTICS
end

function UIManager:draw(global_state)
    self.current_layout = self.layouts[global_state.layout]

    -- Recalculate size and positions
    self.current_layout:measure()
    self.current_layout:layout()

    -- Render
    self.current_layout:draw(global_state)
end

return UIManager
