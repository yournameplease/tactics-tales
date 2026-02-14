local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local portrait_box = require("src.tactics.ui.panels.portrait_box")
require("src.tactics.character.items.object.item")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
require("src.tactics.character.items.object.item_inventory")
local wpn = require("src.tactics.character.items.object.weapon")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local layout = box.layout

local battle = {}

function battle.unit_info(width: integer): box.UIElement
    local root = box.builder("unit_info")
    :layout{
        dir = "row",
        gap = 4,
        padding = layout.padding(4),
        height = "auto",
        width = "fill",
    }
	:build()

    local left = root:add(layout.col_fill())
    left:add(portrait_box.new(function(state: UIContextManager): BattleUnit return state.battle_context.last_hovered_unit end, "paper"))
    left:add(box.spacer(1))

    local info_col = root:add(
    	box.builder()
    	:layout{
	        dir = "col",
	        height = "auto",
	        flex_grow = 1,
	        gap = 2
	    }

    -- ROW 1: Name and Level
    info_col:add(text_node.new({
        rows = 1,
        func = function(_self, state: UIContextManager): {string}
            local u = state.battle_context.last_hovered_unit
            if not u then return { "No Unit Selected" } end
            return { u.character.name }
        end
    }))

    -- ROW 2-4: HP, Weapon
    info_col:add(text_node.new({
        rows = 3,
        func = function(_self, state: UIContextManager): {string}
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
        func = function(_self, state: UIContextManager): {string}
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

    return root
end
