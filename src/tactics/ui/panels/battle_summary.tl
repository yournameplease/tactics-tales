
require("src/tactics/ui/box")
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/panels/portrait_box")
require("src/tactics/character/items/object/item")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/character/items/object/item_inventory")
require("src/tactics/battle/battle_context")

local record BattleSummary
    is UIElement
end

setmetatable(BattleSummary, { __index = Box })

function BattleSummary.new(): BattleSummary
    local self = Box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0, decoration = "border"  })
    self:add(TextNode.new({ rows = 1, func = function(_state: UIContextManager): { string } return { "BATTLE" }  end, draw_properties = {justify = "center"}}))
    self:add(TextNode.new({ rows = 1, func = function(state: UIContextManager): { string }
        local turn = state.battle_context.turn_manager.turn
        return { "Turn " .. turn }
    end, draw_properties = {justify = "center"} }))
    self:add(TextNode.new({ rows = 1, func = function(_state: UIContextManager): {string} return { "Defeat all" }  end, draw_properties = {justify = "center"} }))
	
    return self as BattleSummary
end

return BattleSummary
