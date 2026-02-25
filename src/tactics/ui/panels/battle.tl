local box = require("src.tactics.ui.box")
local book = require("src.tactics.ui.decoration.book")
local character_ui = require("src.tactics.ui.panels.portrait_box")
require("src.tactics.character.items.object.item")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
require("src.tactics.character.items.object.item_inventory")
local wpn = require("src.tactics.character.items.object.weapon")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local combat_calculator = require("src.tactics.battle.combat.combat_calculator")

local battle = {}

local function get_preview_text(self: box.UIElement, state: UIContextManager): {string}
    local attacker = state.battle_context.acting_unit
    local defender = state.battle_context.last_hovered_unit
    local attacker_tile = state.battle_context.destination
    local battle_map = state.battle_context.battle_map
    local preview = combat_calculator.preview_combat(attacker, defender, attacker_tile, battle_map).steps
    
    if preview[1] ~= nil then 
        self.text.content[1] = attacker.character.name .." -> ".. defender.character.name
        self.text.content[2] = "Hit: "..preview[1].hit_chance.."%"
        self.text.content[3] = "Dmg: "..preview[1].dmg
    else
        self.text.content[4] = "No attack!"
        self.text.content[5] = ""
        self.text.content[5] = ""
        
    end
    if preview[2] ~= nil then
        self.text.content[1] = attacker.character.name .." <- ".. defender.character.name
        self.text.content[2] = "Hit: "..preview[2].hit_chance.."%"
        self.text.content[3] = "Dmg: "..preview[2].dmg
    else
        self.text.content[4] = "No counterattack!"
        self.text.content[5] = ""
        self.text.content[5] = ""
    end
end

function battle.battle_summary(): box.UIElement
    local self = box.builder("battle_summary")
    	:direction("col")
    	:container("block")
        :build()

    self:add(
        book.title{
            content = {"BATTLE"}
        })
    self:add(
        box.builder("battle_conditions")
        :layout{
            height = "fit_content"
        }
        :text{
            draw_properties = {
                wrap = "wrap",
                justify = "center",
            },
        }
        :on_update(function(self: box.UIElement, state: UIContextManager): { string }
            self.text.content = state.battle_context.objective_text
        end)
        :build())
	
    return self
end

function battle.unit_info(): box.UIElement
    local root = box.builder("unit_info")
    :layout{
        dir = "row",
        gap = 4,
        padding = box.layout.padding(4),
        height = "fit_content",
        width = "fill",
    }
	:build()

    local left = root
    :add(
        box.builder("unit_info_left")
		:direction("col")
		:container("strip")
        :build())
    left:add(character_ui.portrait_box(function(state: UIContextManager): BattleUnit return state.battle_context.last_hovered_unit end, "paper"))
    left:add(box.spacer(1))

    local info_col = root:add(
    	box.builder("unit_info_right")
    	:layout{
	        dir = "col",
	        height = "fit_content",
	        flex_grow = 1,
	        gap = 2
	    }
	    :build())

    -- ROW 1: Name and Level
    info_col:add(
        box.builder("unit_name")
        :text{
            rows = 1,
        }
        :on_update(function(self: box.UIElement, state: UIContextManager)
            local u = state.battle_context.last_hovered_unit
            if not u then
                self.text.content = { "No Unit Selected" }
            else
                self.text.content = { u.character.name }
            end
        end)
        :build())

    -- ROW 2-4: HP, Weapon
    info_col:add(
        box.builder("unit_name")
        :text{
            rows = 3,
        }
        :on_update(function(self: box.UIElement, state: UIContextManager)
            local u = state.battle_context.last_hovered_unit
            if not u then
                self.text.content = { "", "", "" }
                return
            end
            local weapons = u.character.inventory:get_equipped_weapons()

            local w: wpn.Weapon
            if #weapons > 0 then
                w = weapons[1]
            end
            self.text.content = {
                "HP: " .. u.hp_current .. "/" .. u.character.stats.hp_max,
                w and w.name or "Unarmed",
                w and ("(" .. w.accuracy .. "% for " .. w.damage .. " dmg)") or "",
            }
        end)
        :build())
    
    info_col:add(
        box.builder("unit_name")
        :text{
            rows = 5,
        }
        :on_update(function(self: box.UIElement, state: UIContextManager)
            local u = state.battle_context.last_hovered_unit
            if not u then
                self.text.content = { "", "", "", "", "" }
                return
            end

            local items = u.character.inventory:get_items()

            local out = {"Inventory:", "", "", "", ""}

            local index = 1
            for _,item in ipairs(items) do
                out[index+1] = item.name
                index = index + 1
                for _=2,item.slots do
                    out[index+1] = " |"
                    index = index + 1
                end
            end
        end)
        :build())

    return root
end

function battle.combat_preview(): box.UIElement
    local root = box.builder("combat_preview")
    :layout{
        dir = "row",
        gap = 4,
        padding = box.layout.padding(4),
        height = "fit_content",
        width = "fill",
    }
	:build()

    local attacker_portrait = character_ui.portrait_box(
        function(state: UIContextManager): BattleUnit return state.battle_context.acting_unit end,
        "paper")
    local left = box.builder("combat_preview_left")
		:direction("col")
		:container("strip")
        :build()
    left:add(attacker_portrait)
    left:add(box.spacer(1))

    local defender_portrait = character_ui.portrait_box(
        function(state: UIContextManager): BattleUnit return state.battle_context.hovered_unit end,
        "paper")
    local right = box.builder("combat_preview_right")
		:direction("col")
		:container("strip")
        :build()
    right:add(defender_portrait)
    right:add(box.spacer(1))

    local preview_text = box.builder("combat_preview_center")
    	:layout{
	        dir = "col",
	        height = "fit_content",
	        flex_grow = 1,
	    }
	    :text{}
	    :on_update(get_preview_text)
	    :build()

    root:add(left)
    root:add(preview_text)
    root:add(right)

    return root
end

return battle
