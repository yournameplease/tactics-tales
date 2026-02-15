---@brief
--- Defines the data structures used to hold the transient state
--- for various menu systems.

local point = require("src.tactics.util.point")
local Point = point.Point
require("src.tactics.joypad")
local character = require("src.tactics.character.object.character")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local Item = require("src.tactics.character.items.object.item")
local story_types = require("src.tactics.story.types")

-- Note: some of these extracted types could be kept in menu_manager if tactics_engine and menu_manager didn't require each other
-- Probably, there would be a menu_action_listener or similar to delegate menu commands to the tactics_engine

local record TileSelection
    point: Point
    path: { Point }
end

local record UnitSelection
    point: Point
    unit: BattleUnit
end

local record ItemSelection
    index: integer
    item: Item.Item 
end

local record ScriptSelection
    script_id: integer
    target_unit: BattleUnit 
    target_tile: Point 
end

local enum MenuContextId
    "acting_unit"
    "destination"
    "target_unit"
    "selected_item"
end

local record StorySelection
    id: story_types.StoryId
end

local record CharacterCustomizationSelection
    appearance: { character.CharacterAppearanceKey: string}
end

local interface GameContext
end

-- TODO: move contexts closer to usage

local interface MenuContext
    metadata: {string: any}
end

local record BattleMainMenuContext
    is MenuContext
    acting_unit: UnitSelection
    destination: TileSelection
    target_unit: UnitSelection
    selected_script: ScriptSelection 
    selected_item: ItemSelection
    metadata: {string: any}
end

local record StorySelectMenuContext
    is MenuContext
    metadata: {string: any}
end

local record StoryMenuContext
    is MenuContext
    metadata: {string: any}
    character_customization: CharacterCustomizationSelection 
end

local record GameMainMenuContext
    is MenuContext
    story: StorySelection
    metadata: {string: any}
end

local menu_context = {
	TileSelection = TileSelection,
	UnitSelection = UnitSelection,
	ItemSelection = ItemSelection,
	MenuContextId = MenuContextId,
	StorySelection = StorySelection,
	CharacterCustomizationSelection = CharacterCustomizationSelection,

	GameContext = GameContext,

    MenuContext = MenuContext,
    BattleMainMenuContext = BattleMainMenuContext,
    StorySelectMenuContext = StorySelectMenuContext,
    StoryMenuContext = StoryMenuContext,
    GameMainMenuContext = GameMainMenuContext,
}

return menu_context
