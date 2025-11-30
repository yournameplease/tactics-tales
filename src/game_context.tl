require("src/ui/types")
require("src/battle/tactics/tactics_engine")
require("src/battle/battle_manager")
require("src/turn_manager")
require("src/battle/tile_manager")
require("src/menu/menu_manager")
require("src/character/character_manager")
require("src/systems/event_bus")
require("src/battle/combat/combat_calculator")

global type UILayoutId

global record GameContext
    battle_manager: BattleManager
    tactics: TacticsEngine
    battle_state: BattleState
    turn_manager: TurnManager
    tile_manager: TileManager
    character_manager: CharacterManager
    menu_manager: MenuManager
    event_bus: EventBus
    combat_calculator: CombatCalculator

    layout: UILayoutId

    hovered_unit: BattleUnit
    acting_unit: BattleUnit
end

function GameContext.new(
    battle_manager: BattleManager,
    turn_manager: TurnManager,
    character_manager: CharacterManager,
    menu_manager: MenuManager,
    event_bus: EventBus
): GameContext
    local context: GameContext = {
        battle_manager = battle_manager,
        tactics = battle_manager.tactics_engine,
        battle_state = battle_manager.battle_state,
        turn_manager = turn_manager,
        tile_manager = battle_manager.tactics_engine.tile_manager,
        character_manager = character_manager,
        menu_manager = menu_manager,
        event_bus = event_bus,
        combat_calculator = battle_manager.tactics_engine.combat_calculator,

        layout = "TACTICS",

        hovered_unit = nil,
        acting_unit = nil,
    }
    setmetatable(context, { __index = GameContext })
    return context
end

function GameContext:enrich()
    self.layout = "TACTICS"


    local selection = self.menu_manager.menu_selection

    if selection is GridMenuSelection then
        if self.menu_manager.menu_state.step == "SELECT_UNIT" then
            local point = selection.point
            local unit = self.battle_state:get_at_tile(point)
            if unit then
                self.hovered_unit = unit
            end
        end

        if self.menu_manager.menu_state.step == "SELECT_TARGET" then
            local point = selection.point
            local unit = self.battle_state:get_at_tile(point)
            if unit then
                self.layout = "COMBAT_PREVIEW"
                self.hovered_unit = unit
            end
        end
    end

    if self.menu_manager.menu_ctx.acting_unit ~= nil then
        self.acting_unit = self.menu_manager.menu_ctx.acting_unit.unit
    end

end

return GameContext
