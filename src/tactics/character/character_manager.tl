local event_bus = require("src/tactics/systems/event_bus")
local id_generator = require("src/tactics/util/id_generator")
local event_listener = require("src/tactics/systems/event_bus/event_listener")
local MenuContext = require ("src/tactics/menu/menu_context").MenuContext
local GameData = require("src/tactics/game_data").GameData
-- require("src/tactics/character/animation_data")
-- require("src/tactics/character/items/object/weapon")
local Character = require("src/tactics/character/object/character").Character
local character_generator = require("src/tactics/character/character_generator")
local lists = require("src/tactics/util/lists")
local maps = require("src/tactics/util/maps")

-- Eventually, may want to differentiate between persistent
-- and transient characters.  No real reason now though.
local interface CharacterManager
    generate_character: function(self, template_id: string): Character
    persist_player: function(self, character: Character)
    get_player_roster: function(self): { Character }
    teardown: function(self) 
end

local character_manager = {
    CharacterManager = CharacterManager
}

local record CharacterManagerImpl
    is CharacterManager

    game_data: GameData

    event_listener: event_listener.EventListener
    
    id_generator: id_generator.IdGenerator
    characters: { integer: Character }

    player_ids: { integer }
end

function CharacterManagerImpl:generate_character(
    template_id: string
): Character
    local character: Character = character_generator.generate_from_template(
        self.id_generator:get_id(),
        template_id,
        self.game_data
    )

    return character
end

function CharacterManagerImpl:persist_player(character: Character)
    self.characters[character.id] = character
    pt.add(self.player_ids, character.id)
end

function CharacterManagerImpl:get_player_roster(): { Character }
    return lists.map(
        maps.get_at(self.characters)
    )(self.player_ids)
end

-- event handlers

function CharacterManagerImpl:handle_equip_item(ctx: MenuContext)
    local character = ctx.acting_unit.unit.character
    local item_index = ctx.selected_item.index
    character.inventory:equip_item(item_index)
end

function CharacterManagerImpl:handle_unequip_item(ctx: MenuContext)
    local character = ctx.acting_unit.unit.character
    local item_index = ctx.selected_item.index
    character.inventory:unequip_item(item_index)
end

function CharacterManagerImpl:handle_discard_item(ctx: MenuContext)
    local character = ctx.acting_unit.unit.character
    local item_index = ctx.selected_item.index
    character.inventory:remove_item(item_index)
end

function character_manager.new(
    game_data: GameData,
    bus: event_bus.EventBus
): CharacterManager
    local self: CharacterManagerImpl = setmetatable({
        event_listener = event_listener.new(bus)
    }, { __index = CharacterManagerImpl})

    self.id_generator = id_generator.new()
    self.game_data = game_data
    self.characters = {}
    self.player_ids = {}

    self.event_listener:on("INVENTORY_EQUIP_ITEM", function(ctx: MenuContext)
        self:handle_equip_item(ctx)
    end)
    self.event_listener:on("INVENTORY_UNEQUIP_ITEM", function(ctx: MenuContext)
        self:handle_unequip_item(ctx)
    end)
    self.event_listener:on("INVENTORY_DISCARD_ITEM", function(ctx: MenuContext)
        self:handle_discard_item(ctx)
    end)

    return self
end

function CharacterManagerImpl:teardown()
    self.event_listener:teardown()
end

return character_manager
