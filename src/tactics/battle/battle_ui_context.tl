local point = require("src/tactics/util/point")
local Point = point.Point
local ui_context = require("src/tactics/ui/ui_context")
local turn_manager =require("src/tactics/turn_manager")
require("src/tactics/battle/battle_menu_manager")
local BattleMenuContext = require("src/tactics/battle/battle_menu_context").BattleMenuContext
local grid_cursor = require("src/tactics/menu/cursor/grid_cursor")

local record BattleUIContext
    is ui_context.UIContext
    where self.type == "battle"

    battle_map: BattleMap
    battle_menu_manager: BattleMenuManager
    turn_manager: turn_manager.TurnManager
    
    hovered_unit: BattleUnit
    last_hovered_unit: BattleUnit
    acting_unit: BattleUnit
    destination: Point
end

local battle_ui_context = {
    BattleUIContext = BattleUIContext
}

function battle_ui_context.new(
    battle_map: BattleMap,
    battle_menu_mgr: BattleMenuManager,
    turn_mgr: turn_manager.TurnManager
): BattleUIContext
    local self: BattleUIContext = setmetatable({
        type = "battle"
    }, { __index = BattleUIContext })

    self.layout = "TACTICS"
    
    self.battle_map = battle_map
    self.battle_menu_manager = battle_menu_mgr
    self.turn_manager = turn_mgr

    self.last_hovered_unit = nil
    self.hovered_unit = nil
    self.acting_unit = nil
    return self
end

function BattleUIContext:enrich()
    self.layout = "TACTICS"

    self.hovered_unit = nil
    local selection = self.battle_menu_manager.menu_cursor

    if selection is grid_cursor.GridMenuCursor<BattleMenuContext> then
        if self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            local selection_point = selection.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.last_hovered_unit = unit
            end
        end

        if self.battle_menu_manager.menu_state.step == "SELECT_TARGET" then
            local selection_point = selection.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.layout = "COMBAT_PREVIEW"
                self.last_hovered_unit = unit
            end
        end
    end

    if self.battle_menu_manager.menu_ctx.acting_unit ~= nil then
        self.acting_unit = self.battle_menu_manager.menu_ctx.acting_unit.unit
    end

    if self.battle_menu_manager.menu_ctx.destination ~= nil then
        self.destination = self.battle_menu_manager.menu_ctx.destination.point
    end

    if selection is grid_cursor.GridMenuCursor<BattleMenuContext> then
        if self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            self.acting_unit = nil
        end
    end
end

return battle_ui_context
