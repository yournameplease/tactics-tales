require("src/types")

require("src/game_context")
local CONFIG = require("src/config")

local TacticsMap = require("src/ui/panels/tactics_map")
require("src/ui/box")
require("src/ui/panels/unit_info")
require("src/ui/panels/combat_preview")
require("src/ui/panels/text_node")
require("src/ui/panels/event_message_log")

local MenuValidator = require("src/ui/validator")

global enum UILayoutId
    "TACTICS"
    "COMBAT_PREVIEW"
end

global record UILayout
    root: UIElement
end

global record UIManager
    layouts: { UILayoutId: UILayout }
    current_layout: UIElement
    theme: UITheme
end

-- Define Layouts
function UIManager.new(): UIManager

    local self: UIManager = setmetatable({}, { __index = UIManager }) 
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    local battle_summary = Box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0 })
    battle_summary:add(TextNode.new({ func = function(state: GameContext): { string } return { "BATTLE" }  end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function(state: GameContext): { string }
        local turn = state.turn_manager.get_turn()
        return { "Turn " .. turn }
    end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function(state: GameContext): {string} return { "Defeat all" }  end, justify = "center" }))
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

    self.theme = {
        COLOR_DECORATION_PRIMARY = 22,
        COLOR_DECORATION_HIGHLIGHT = 6,
        COLOR_DECORATION_SHADOW = 5,
        COLOR_INTERIOR = 21,
        COLOR_INTERIOR_TEXT = 7,
    }
end

function UIManager:draw(game_context: GameContext)
    self.current_layout = self.layouts[game_context.layout]

    -- Recalculate size and positions
    self.current_layout:measure()
    self.current_layout:layout()

    -- Render
    self.current_layout:draw(game_context, self.theme)
end

return UIManager
