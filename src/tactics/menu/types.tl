local point = require("src/tactics/util/point")
local Point = point.Point
require("src/tactics/joypad")
local character = require("src/tactics/character/object/character")
local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
local Item = require("src/tactics/character/items/object/item")
local story_types = require("src/tactics/story/types")

-- Note: some of these extracted types could be kept in menu_manager if tactics_engine and menu_manager didn't require each other
-- Probably, there would be a menu_action_listener or similar to delegate menu commands to the tactics_engine

global record TileSelection
    point: Point
    path: { Point }
end

global record UnitSelection
    point: Point
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

global record StorySelection
    id: story_types.StoryId
end

global record CharacterCustomizationSelection
    appearance: { character.CharacterAppearanceKey: string}
end

-- todo: this should be an interface...?
global record MenuContext
    acting_unit: UnitSelection
    destination: TileSelection
    target_unit: UnitSelection
    selected_item: ItemSelection
    story: StorySelection
    character_customization: CharacterCustomizationSelection 
    metadata: {string: any}
end

global type MenuId = string
global type MenuStep = string


global record MenuState
    step: MenuStep
    menu_id: MenuId
    point: Point
end
