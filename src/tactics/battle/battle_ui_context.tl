local ui_context = require("src/tactics/ui/ui_context")
require("src/tactics/ui/types")
require("src/tactics/battle/tactics/tactics_engine")
require("src/tactics/turn_manager")
require("src/tactics/battle/pathfinding")
require("src/tactics/battle/battle_menu_manager")
require("src/tactics/character/character_manager")
require("src/tactics/systems/event_bus")

global type UILayoutId

local record BattleUIContext
    is ui_context.UIContext
    where self.type == "battle"

    battle_map: BattleMap
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager
    
    hovered_unit: BattleUnit
    acting_unit: BattleUnit
    destination: TilePoint
end

local battle_ui_context = {
    BattleUIContext = BattleUIContext
}

function battle_ui_context.new(
    battle_map: BattleMap,
    battle_menu_manager: BattleMenuManager,
    turn_manager: TurnManager
): BattleUIContext
    local self: BattleUIContext = setmetatable({
        type = "battle"
    }, { __index = BattleUIContext })

    self.layout = "TACTICS"
    
    self.battle_map = battle_map
    self.battle_menu_manager = battle_menu_manager
    self.turn_manager = turn_manager

    self.hovered_unit = nil
    self.acting_unit = nil
    return self
end

function BattleUIContext:enrich()
    self.layout = "TACTICS"


    local selection = self.battle_menu_manager.menu_cursor

    if selection is GridMenuCursor<BattleMenuContext> then
        if self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            local point = selection.point
            local unit = self.battle_map:get_at_tile(point)
            if unit then
                self.hovered_unit = unit
            end
        end

        if self.battle_menu_manager.menu_state.step == "SELECT_TARGET" then
            local point = selection.point
            local unit = self.battle_map:get_at_tile(point)
            if unit then
                self.layout = "COMBAT_PREVIEW"
                self.hovered_unit = unit
            end
        end
    end

    if self.battle_menu_manager.menu_ctx.acting_unit ~= nil then
        self.acting_unit = self.battle_menu_manager.menu_ctx.acting_unit.unit
    end

    if self.battle_menu_manager.menu_ctx.destination ~= nil then
        self.destination = self.battle_menu_manager.menu_ctx.destination.point
    end

end

return battle_ui_context
