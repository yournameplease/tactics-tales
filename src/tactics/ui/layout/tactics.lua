---@brief
--- Defines the main UI layout for the tactical battle screen.
local tactics_map = require("src.tactics.ui.panels.tactics_map")
local box = require("src.tactics.ui.box")
local battle = require("src.tactics.ui.panels.battle")
local control_hints = require("src.tactics.ui.panels.control_hints")

local book = require("src.tactics.ui.decoration.book")
local tactics_modal = require("src.tactics.ui.modal.tactics")

---@type table<UILayoutId, UILayout>
local layouts = {}

local battle_summary = battle.battle_summary()
local map = tactics_map.new()

---@type ModalLayout[]
local modals = {
    {
        node = tactics_modal.tactics_dialogue_menu(),
    },
    {
        node = tactics_modal.tactics_action_menu(),
    },
}

do
    local left = book.flex_page()
    left:add(battle_summary)
    local unit_box = box.builder("unit_box")
        :layout {
            dir = "col",
            gap = 4,
            padding = box.layout.padding(4),
            height = "fit_content",
            width = "fill",
        }
        :style {
            decoration = "border",
            decoration_padding = 3,
        }
        :build()
    unit_box:add(battle.unit_info())
    unit_box:add(battle.unit_inventory())
    left:add(unit_box)
    left:add(box.spacer(1))
    left:add(control_hints.new(
    ---@param s UIContextManager
        function(s)
            return s.battle_context.battle_menu_manager.menu_step
        end,
        {}
    ))
    local right = book.fit_page()
    right:add(map)

    layouts["TACTICS"] = {
        root = book.split_pages(left, map),
        modals = modals,
    }
end

do
    local left = book.flex_page()
    left:add(battle_summary)
    left:add(battle.combat_preview())
    left:add(box.spacer(1))
    left:add(control_hints.new(
    ---@param s UIContextManager
        function(s)
            return s.battle_context.battle_menu_manager.menu_step
        end,
        {}
    ))
    local right = book.fit_page()
    right:add(map)

    layouts["COMBAT_PREVIEW"] = {
        root = book.split_pages(left, map),
        modals = modals,
    }
end

return layouts
