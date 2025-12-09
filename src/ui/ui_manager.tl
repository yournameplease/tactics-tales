require("src/systems/service")
require("src/types")
require("src/ui/types")

require("src/battle/battle_ui_context")
require("src/config")

require("src/ui/panels/tactics_map")
require("src/ui/box")
require("src/ui/panels/unit_info")
require("src/ui/panels/combat_preview")
require("src/ui/panels/text_node")
require("src/ui/panels/event_message_log")

local PageDivider = require("src/ui/decoration/page_divider")

require("src/ui/validator")

global record UILayout
    root: UIElement
end

global record UIManager
    is GameService
    where self.id == "ui_manager"
    layouts: { UILayoutId: UILayout }
    current_layout: UILayout
    theme: UITheme
end

function UIManager:init(_service_manager: ServiceManager, _services: { ServiceId: GameService })

end

-- Define Layouts
function UIManager.new(): UIManager

    local self: UIManager = setmetatable({
        id = "ui_manager",
        dependencies = {},
    }, { __index = UIManager }) 
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    local battle_summary = Box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0, decoration = "border"  })
    battle_summary:add(TextNode.new({ func = function(_state: UIContextManager): { string } return { "BATTLE" }  end, justify = "center"}))
    battle_summary:add(TextNode.new({ func = function(state: UIContextManager): { string }
        local turn = state.battle_ui_context.turn_manager.turn
        return { "Turn " .. turn }
    end, justify = "center" }))
    battle_summary:add(TextNode.new({ func = function(_state: UIContextManager): {string} return { "Defeat all" }  end, justify = "center" }))

    local page_divider = PageDivider.new(7)

    local tactics_map = TacticsMap.new(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT,
            {
                decoration_padding = 2,
                decoration = "border",
                internal_margin = { t = 5, b = 5, l = 4, r = 4 }
            })
    
    do
        local battle_root = Box.new({
            x=0, y=0,
            w=480, h=270,
            internal_margin = {t = 4},
            gap=0,
            padding=0, 
            dir="row",
            transparent = true
        })

        -- Left Sidebar
        local left = battle_root:add(Box.new({ dir="col", flex_grow = 1, padding = 2}))
        left:add(battle_summary)
        left:add(UnitInfo.new({ padding = 2, decoration = "border"  }))
        left:add(EventMessageLog.new({ padding = 2, flex_grow = 1, decoration = "border" }))

        battle_root:add(page_divider)
        battle_root:add(tactics_map)

        self.layouts["TACTICS"]= { root = battle_root }
    end
    do
        local battle_root = Box.new({
            x=0, y=0,
            w=480, h=270,
            internal_margin = {t = 4},
            dir="row",
            transparent = true
        })

        -- Left Sidebar
        local left = battle_root:add(Box.new({ dir="col", flex_grow = 1, padding = 2}))
        left:add(battle_summary)
        left:add(CombatPreview.new({ padding = 0, decoration = "border"  }))
        left:add(EventMessageLog.new({ flex_grow = 1, decoration = "border" }))

        battle_root:add(page_divider)
        battle_root:add(tactics_map)

        self.layouts["COMBAT_PREVIEW"] = { root = battle_root }
    end

    -- Validate all layouts
    for id, v in pairs(self.layouts) do
        MenuValidator.validate(v.root, id)
    end

    -- Set initial
    self.current_layout = self.layouts.TACTICS

    -- old "stone" theme
    -- self.theme = {
    --     COLOR_DECORATION_PRIMARY = 22,
    --     COLOR_DECORATION_HIGHLIGHT = 6,
    --     COLOR_DECORATION_SHADOW = 5,
    --     COLOR_INTERIOR = 21,
    --     COLOR_INTERIOR_TEXT = 7,
    -- }
    self.theme = {
        COLOR_DECORATION_PRIMARY = 4,
        COLOR_DECORATION_HIGHLIGHT = 31,
        COLOR_DECORATION_SHADOW = 20,
        COLOR_INTERIOR = 15,
        COLOR_INTERIOR_TEXT = 21,
        COLOR_CLEAR = 20
    }

    return self
end

function UIManager:draw(battle_ui_context: UIContextManager)
    self.current_layout = self.layouts[battle_ui_context.layout]

    local root = self.current_layout.root
    -- Recalculate size and positions
    root:measure()
    root:layout(root.x, root.y)

    -- Render
    cls(self.theme.COLOR_CLEAR)
    root:draw(battle_ui_context, self.theme)
end

return UIManager
