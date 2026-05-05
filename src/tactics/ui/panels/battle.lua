---@brief UI panel builders for battle screens: summary, unit info, inventory, and combat preview.

local box = require("src.tactics.ui.box")
local book = require("src.tactics.ui.decoration.book")
local character_ui = require("src.tactics.ui.panels.portrait_box")
require("src.tactics.character.items.object.item")
require("src.tactics.character.items.object.item_inventory")
local combat_calculator = require("src.tactics.battle.combat.combat_calculator")

local battle = {}

--- Populate attacker combat preview text from combat calculator results.
---@param self UIElement
---@param state UIContextManager
local function get_attacker_preview_text(self, state)
    local attacker = state.battle_context.acting_unit
    local defender = state.battle_context.last_hovered_unit
    local attacker_tile = state.battle_context.destination
    local battle_map = state.battle_context.battle_map
    local preview = combat_calculator.preview_combat(attacker, defender, attacker_tile, battle_map).steps

    if preview[1] ~= nil then
        self.text.content[1] = attacker.character.name .. " -> " .. defender.character.name
        self.text.content[2] = "Hit: " .. preview[1].hit_chance .. "%"
        self.text.content[3] = "Dmg: " .. preview[1].dmg
    else
        self.text.content[1] = "No attack!"
        self.text.content[2] = ""
        self.text.content[3] = ""
    end
end

--- Populate defender counterattack preview text from combat calculator results.
---@param self UIElement
---@param state UIContextManager
local function get_defender_preview_text(self, state)
    local attacker = state.battle_context.acting_unit
    local defender = state.battle_context.last_hovered_unit
    local attacker_tile = state.battle_context.destination
    local battle_map = state.battle_context.battle_map
    local preview = combat_calculator.preview_combat(attacker, defender, attacker_tile, battle_map).steps

    if preview[2] ~= nil then
        self.text.content[1] = attacker.character.name .. " <- " .. defender.character.name
        self.text.content[2] = "Hit: " .. preview[2].hit_chance .. "%"
        self.text.content[3] = "Dmg: " .. preview[2].dmg
    else
        self.text.content[1] = "No counteattack!"
        self.text.content[2] = ""
        self.text.content[3] = ""
    end
end

--- Build the battle summary panel showing the title and objective text.
---@return UIElement
function battle.battle_summary()
    local self = box.builder("battle_summary")
        :direction("col")
        :container("block")
        :build()

    self:add(
        book.title {
            content = { "\014BATTLE" }
        })
    self:add(
        box.builder("battle_conditions")
        :layout {
            height = "fit_content"
        }
        :text {
            draw_properties = {
                wrap = "wrap",
                justify = "center",
            },
        }
        :on_update(function(s, state)
            s.text.content = state.battle_context.objective_text
        end)
        :build())

    return self
end

--- Build the unit info panel showing portrait, name, HP, and weapon stats for the hovered unit.
---@return UIElement
function battle.unit_info()
    local root = box.builder("unit_info")
        :layout {
            dir = "row",
            gap = 4,
            padding = box.layout.padding(0),
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
    left:add(character_ui.portrait_box(function(state) return state.battle_context.last_hovered_unit end, "paper"))
    left:add(box.spacer(1))

    local info_col = root:add(
        box.builder("unit_info_right")
        :layout {
            dir = "col",
            height = "fit_content",
            flex_grow = 1,
            gap = 2
        }
        :build())

    -- ROW 1: Name and Level
    info_col:add(
        box.builder("unit_name")
        :text {
            rows = 1,
        }
        :on_update(function(self, state)
            local u = state.battle_context.last_hovered_unit
            if not u then
                self.text.content = { "No Unit Selected" }
            else
                self.text.content = { "\014" .. u.character.name }
            end
        end)
        :build())

    -- ROW 2-4: HP, Weapon
    info_col:add(
        box.builder("unit_name")
        :text {
            rows = 1,
        }
        :on_update(function(self, state)
            local u = state.battle_context.last_hovered_unit
            if not u then
                self.text.content = { "" }
                return
            end

            self.text.content = {
                "HP: " .. u.hp_current .. "/" .. u.character.stats.hp_max,
            }
        end)
        :build())

    return root
end

--- Build the unit inventory panel listing equipped items and their effects for the hovered unit.
---@return UIElement
function battle.unit_inventory()
    local out = box.builder("unit_inventory")
        :direction "col"
        :container "block"
        :padding(4)
        :style {
            -- decoration = "border",
        }
        :text {
            draw_properties = {
                wrap = "wrap",
            },
        }
        :on_update(function(self, state)
            local u = state.battle_context.last_hovered_unit
            if not u then
                self.text.content = {}
                self.style.decoration_padding = 0
                return
            end

            local items = u.character.inventory:get_item_descriptions()

            local out = {}

            if u.tags["hero"] then
                table.insert(out, "\014Hero:\015 Game over if slain.")
            end
            if u.tags["monarch"] then
                table.insert(out, "\014Monarch:\015 Game over if slain.")
            end
            if u.tags["boss"] then
                table.insert(out, "\014Boss:\015 Defeat all bosses to win the chapter.")
            end

            for _, d in ipairs(items) do
                if d.name then
                    table.insert(out, "\014" .. d.name)
                end
                if d.damage then
                    table.insert(out, "> " .. d.damage .. " damage")
                end
                if d.targeting_description then
                    table.insert(out, "> " .. d.targeting_description)
                end
                if d.effects then
                    for _, e in ipairs(d.effects) do
                        if e.should_display_name and e.name and e.description then
                            table.insert(out, "> " .. e.name .. ": " .. e.description)
                        elseif e.should_display_name and e.name then
                            table.insert(out, "> " .. e.name)
                        elseif e.description then
                            table.insert(out, "> " .. e.description)
                        end
                    end
                end
            end
            self.text.content = out
            self.style.decoration_padding = 2
        end)
        :build()

    return out
end

--- Build the combat preview panel showing attacker and defender portraits with hit/damage predictions.
---@return UIElement
function battle.combat_preview()
    local root = box.builder("combat_preview")
        :direction("col")
        :container("block")
        :padding(4)
        :build()

    local attacker_portrait = character_ui.portrait_box(
        function(state) return state.battle_context.acting_unit end,
        "paper")
    local top_left = box.builder("combat_preview_left")
        :direction("col")
        :container("strip")
        :build()
    top_left:add(attacker_portrait)
    top_left:add(box.spacer(1))

    local defender_portrait = character_ui.portrait_box(
        function(state) return state.battle_context.hovered_unit end,
        "paper")
    local bottom_right = box.builder("combat_preview_right")
        :direction("col")
        :container("strip")
        :build()
    bottom_right:add(defender_portrait)
    bottom_right:add(box.spacer(1))

    local top_right_text = box.builder("combat_preview_center")
        :layout {
            dir = "col",
            height = "fit_content",
            flex_grow = 1,
        }
        :text {
            draw_properties = {
                justify = "center"
            }
        }
        :on_update(get_attacker_preview_text)
        :build()

    local bottom_left_text = box.builder("combat_preview_center")
        :layout {
            dir = "col",
            height = "fit_content",
            flex_grow = 1,
        }
        :text {
            draw_properties = {
                justify = "center"
            }
        }
        :on_update(get_defender_preview_text)
        :build()

    local top_row = box.builder("combat_attacker_preview")
        :direction("row")
        :container("strip")
        :build()
    top_row:add(top_left)
    top_row:add(top_right_text)

    local bottom_row = box.builder("combat_attacker_preview")
        :direction("row")
        :container("strip")
        :build()
    bottom_row:add(bottom_left_text)
    bottom_row:add(bottom_right)

    root:add(top_row)
    root:add(bottom_row)

    return root
end

return battle
