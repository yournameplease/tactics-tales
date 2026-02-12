---@brief
--- A UI panel that displays a summary of the current battle's objectives.

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
require("src.tactics.character.items.object.item")
require("src.tactics.character.items.object.item_inventory")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local record BattleSummary
    is box.UIElement
end

setmetatable(BattleSummary, { __index = box.Box })

function BattleSummary.new(): BattleSummary
    local self = box.new({ x = 0, y = 0, auto_height = true, dir = "col", gap = 0 })
    self:add(text_node.title({ func = function(_state: UIContextManager): { string } return { "BATTLE" }  end }))
    self:add(text_node.new({
        auto_height = true,
        func = function(_self, state: UIContextManager): { string }
            return state.battle_context.objective_text
        end,
        draw_properties = {
            wrap = "wrap",
            justify = "center",
        } }))
	
    return self as BattleSummary
end

return BattleSummary
