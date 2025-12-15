require("src/types")
require("src/joypad")
require("src/systems/event_bus")
require("src/battle/tactics/battle_unit")
local Item = require("src/character/items/object/item")

-- Note: some of these extracted types could be kept in menu_manager if tactics_engine and menu_manager didn't require each other
-- Probably, there would be a menu_action_listener or similar to delegate menu commands to the tactics_engine

global record MenuTileHighlight
    reachable: boolean
    valid_selection: boolean
    can_attack: boolean
end

global enum MenuType
    "CURSOR_GRID"
    "CURSOR_LIST"
    "CURSOR_BUTTON_ADVANCE"
    "CURSOR_MULTIPLE_OPTIONS"
end

global record TileSelection
    point: TilePoint
    path: { TilePoint }
end

global record UnitSelection
    point: TilePoint
    unit: BattleUnit
end

global record ItemSelection
    index: integer
    item: Item.Item 
end

global enum MenuContextId
    "acting_unit"
    "destination"
    "target_unit"
    "selected_item"
end

-- todo: this should be an interface
global record MenuContext
    acting_unit: UnitSelection
    destination: TileSelection
    target_unit: UnitSelection
    selected_item: ItemSelection
    metadata: {string: any}
end

global type MenuId = string
global type MenuStep = string


global record MenuState
    step: MenuStep
    menu_id: MenuId
    point: TilePoint
end
