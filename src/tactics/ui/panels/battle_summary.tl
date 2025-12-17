
require("src/ui/box")
require("src/ui/components/text_node")
require("src/ui/panels/portrait_box")
require("src/character/items/object/item")
require("src/ui/ui_context_manager")
require("src/character/items/object/item_inventory")
require("src/battle/battle_context")

local record BattleSummary
    is UIElement
end

setmetatable(BattleSummary, { __index = Box })

function BattleSummary.new(): BattleSummary
    local self = Box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0, decoration = "border"  })
    self:add(TextNode.new({ func = function(_state: UIContextManager): { string } return { "BATTLE" }  end, draw_properties = {justify = "center"}}))
    self:add(TextNode.new({ func = function(state: UIContextManager): { string }
        local turn = state.battle_context.ctx.turn_manager.turn
        return { "Turn " .. turn }
    end, draw_properties = {justify = "center"} }))
    self:add(TextNode.new({ func = function(_state: UIContextManager): {string} return { "Defeat all" }  end, draw_properties = {justify = "center"} }))
	
    return self as BattleSummary
end

return BattleSummary
