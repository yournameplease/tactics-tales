
local box = require("src/tactics/ui/box")
local text_node = require("src/tactics/ui/components/text_node")
require("src/tactics/character/items/object/item")
require("src/tactics/character/items/object/item_inventory")
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager

local record BattleSummary
    is box.UIElement
end

setmetatable(BattleSummary, { __index = box.Box })

function BattleSummary.new(): BattleSummary
    local self = box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0 })
    self:add(text_node.title({ func = function(_state: UIContextManager): { string } return { "BATTLE" }  end }))
    self:add(text_node.new({ rows = 1, func = function(state: UIContextManager): { string }
        local turn = state.battle_context.turn_manager.turn
        return { "Turn " .. turn }
    end, draw_properties = {justify = "center"} }))
    self:add(text_node.new({ rows = 1, func = function(_state: UIContextManager): {string} return { "Defeat all" }  end, draw_properties = {justify = "center"} }))
	
    return self as BattleSummary
end

return BattleSummary
