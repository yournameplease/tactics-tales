require("src/tactics/ui/types")
require("src/tactics/battle/tactics/tactics_engine")
require("src/tactics/turn_manager")
require("src/tactics/battle/pathfinding")
require("src/tactics/battle/battle_menu_manager")
require("src/tactics/character/character_manager")
require("src/tactics/systems/event_bus")

global type UILayoutId

global record BattleUIContext
    ctx: BattleContext

    layout: UILayoutId

    hovered_unit: BattleUnit
    acting_unit: BattleUnit
    destination: TilePoint
end

function BattleUIContext.new(ctx: BattleContext): BattleUIContext
    local self: BattleUIContext = setmetatable({}, { __index = BattleUIContext })

    self.ctx = ctx

    self.layout = "TACTICS"

    self.hovered_unit = nil
    self.acting_unit = nil
    return self
end

function BattleUIContext:enrich()
    self.layout = "TACTICS"


    local selection = self.ctx.battle_menu_manager.menu_cursor

    if selection is GridMenuCursor<BattleContext> then
        if self.ctx.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            local point = selection.point
            local unit = self.ctx.battle_map:get_at_tile(point)
            if unit then
                self.hovered_unit = unit
            end
        end

        if self.ctx.battle_menu_manager.menu_state.step == "SELECT_TARGET" then
            local point = selection.point
            local unit = self.ctx.battle_map:get_at_tile(point)
            if unit then
                self.layout = "COMBAT_PREVIEW"
                self.hovered_unit = unit
            end
        end
    end

    if self.ctx.battle_menu_manager.menu_ctx.acting_unit ~= nil then
        self.acting_unit = self.ctx.battle_menu_manager.menu_ctx.acting_unit.unit
    end

    if self.ctx.battle_menu_manager.menu_ctx.destination ~= nil then
        self.destination = self.ctx.battle_menu_manager.menu_ctx.destination.point
    end

end

return BattleUIContext
