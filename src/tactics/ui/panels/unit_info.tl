---@brief
--- A UI panel that displays detailed information about a selected unit.

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local portrait_box = require("src.tactics.ui.panels.portrait_box")
require("src.tactics.character.items.object.item")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
require("src.tactics.character.items.object.item_inventory")
local wpn = require("src.tactics.character.items.object.weapon")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit

local record UnitInfo
    is box.UIElement
end
setmetatable(UnitInfo, { __index = box.Box })

local unit_info = {}

function unit_info.new(props: UnitInfo): UnitInfo
    props.dir = "row"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true

    local self = box.new(props) as UnitInfo
    setmetatable(self, { __index = UnitInfo })

    local left = self:add(box.flex_col())
    left:add(portrait_box.new(function(state: UIContextManager): BattleUnit return state.battle_context.last_hovered_unit end, "paper"))
    left:add(box.spacer(1))

    local info_col = self:add(box.new({
        auto_height = true,
        flex_grow = 1,
        dir = "col",
        gap = 2
    }))

    -- ROW 1: Name and Level
    info_col:add(text_node.new({
        rows = 1,
        func = function(state: UIContextManager): {string}
            local u = state.battle_context.last_hovered_unit
            if not u then return { "No Unit Selected" } end
            return { u.character.name }
        end
    }))

    -- ROW 2-4: HP, Weapon
    info_col:add(text_node.new({
        rows = 3,
        func = function(state: UIContextManager): {string}
            local u = state.battle_context.last_hovered_unit
            if not u then return { "", "", "" } end

            local weapons = u.character.inventory:get_equipped_weapons()

            local w: wpn.Weapon
            if #weapons > 0 then
                w = weapons[1]
            end

            return {
                "HP: " .. u.hp_current .. "/" .. u.character.stats.hp_max,
                w and w.name or "Unarmed",
                w and ("(" .. w.accuracy .. "% for " .. w.damage .. " dmg)") or "",
            }
        end
    }))
    
    info_col:add(text_node.new({
        rows = 5,
        func = function(state: UIContextManager): {string}
            local u = state.battle_context.last_hovered_unit
            if not u then return { "", "", "", "", "" } end

            local items = u.character.inventory:get_items()

            local out = {"Inventory:", "", "", "", ""}

            local index = 1
            for _,item in ipairs(items) do
                out[index+1] = item:get_name()
                index = index + 1
                for _=2,item:get_slots() do
                    out[index+1] = " |"
                    index = index + 1
                end
            end

            return out
        end
    }))

    return self
end

return unit_info
