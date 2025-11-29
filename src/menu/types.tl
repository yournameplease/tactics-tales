require("src/types")
require("src/joypad")
require("src/systems/event_bus")
require("src/tactics/battle_unit")

-- Note: some of these extracted types could be kept in menu_manager if tactics_engine and menu_manager didn't require each other
-- Probably, there would be a menu_action_listener or similar to delegate menu commands to the tactics_engine

global record MenuTileHighlight
    reachable: boolean
    valid_selection: boolean
    can_attack: boolean
end

global enum MenuType
    "CURSOR_GRID"
    "CURSOR_VERTICAL_LIST"
    "CURSOR_HORIZONTAL_LIST"
end

global record TileSelection
    point: TilePoint
    path: { TilePoint }
end

global record UnitSelection
    point: TilePoint
    unit: BattleUnit
end

global enum MenuContextId
    "acting_unit"
    "destination"
    "target_unit"
end

-- todo: can I use the ContextId without losing type information?
global record MenuContext
    acting_unit: UnitSelection
    destination: TileSelection
    target_unit: UnitSelection
end

global type MenuId = string
global type MenuStep = string


global record MenuState
    step: MenuStep
    menu_id: MenuId
    point: TilePoint
end
