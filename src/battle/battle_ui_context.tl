require("src/ui/types")
require("src/battle/tactics/tactics_engine")
require("src/turn_manager")
require("src/battle/tile_manager")
require("src/menu/battle_menu_manager")
require("src/character/character_manager")
require("src/systems/event_bus")
require("src/battle/combat/combat_calculator")

global type UILayoutId

global record BattleUIContext
    is TransientGameService
    where self.id == 'battle_ui_context'
    tactics: TacticsEngine
    battle_state: BattleState
    turn_manager: TurnManager
    tile_manager: TileManager
    character_manager: CharacterManager
    battle_menu_manager: BattleMenuManager
    event_bus: EventBus -- move to a debug context
    combat_calculator: CombatCalculator

    layout: UILayoutId

    hovered_unit: BattleUnit
    acting_unit: BattleUnit
    destination: TilePoint
end

function BattleUIContext:init(_service_manager: ServiceManager, services: { ServiceId: GameService })
    self.tactics = services.tactics_engine as TacticsEngine
    self.battle_state = services.battle_state as BattleState
    self.turn_manager = services.turn_manager as TurnManager
    self.tile_manager = services.tile_manager as TileManager
    self.character_manager = services.character_manager as CharacterManager
    self.battle_menu_manager = services.battle_menu_manager as BattleMenuManager
    self.event_bus = services.event_bus as EventBus
    self.combat_calculator = services.combat_calculator as CombatCalculator

    self.layout = "TACTICS"

    self.hovered_unit = nil
    self.acting_unit = nil
end

function BattleUIContext.new(): BattleUIContext
    local context: BattleUIContext = setmetatable({
        id = "battle_ui_context",
        dependencies = {
            "tactics_engine",
            "battle_state",
            "turn_manager",
            "tile_manager",
            "character_manager",
            "battle_menu_manager",
            "event_bus",
            "combat_calculator",
        }
    }, { __index = BattleUIContext })
    return context
end

function BattleUIContext:enrich()
    self.layout = "TACTICS"


    local selection = self.battle_menu_manager.menu_selection

    if selection is GridMenuSelection then
        if self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            local point = selection.point
            local unit = self.battle_state:get_at_tile(point)
            if unit then
                self.hovered_unit = unit
            end
        end

        if self.battle_menu_manager.menu_state.step == "SELECT_TARGET" then
            local point = selection.point
            local unit = self.battle_state:get_at_tile(point)
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

return BattleUIContext
