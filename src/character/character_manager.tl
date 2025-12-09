require("src/debug")
require("src/util")
require("src/systems/event_bus")
require("src/menu/types")
require("src/character/animation_data")
require("src/character/items/object/weapon")
require("src/animation")
require("src/character/object/character")
require("src/systems/service")
local CharacterGenerator = require("src/character/character_generator")

-- Eventually, may want to differentiate between persistent
-- and transient characters.  No real reason now though.
global record CharacterManager
    is GameService
    where self.id == 'character_manager'
    id_counter: IdCounter
    characters: { Character }

    event_bus: EventBus
end

function CharacterManager:generate_character(template_id: string): Character
    local character: Character = CharacterGenerator.generate_from_template(
        self.id_counter:get_id(),
        template_id
    )

    self.characters[character.id] = character

    return character
end

-- handlers

function CharacterManager:handle_equip_item(ctx: MenuContext)
    local character = ctx.acting_unit.unit.character
    local item_index = ctx.selected_item.index
    character.inventory:equip_item(item_index)
end

function CharacterManager:handle_unequip_item(ctx: MenuContext)
    local character = ctx.acting_unit.unit.character
    local item_index = ctx.selected_item.index
    character.inventory:unequip_item(item_index)
end

function CharacterManager:handle_discard_item(ctx: MenuContext)
    local character = ctx.acting_unit.unit.character
    local item_index = ctx.selected_item.index
    character.inventory:remove_item(item_index)
end

function CharacterManager:init(_service_manager: ServiceManager, services: { ServiceId: GameService })
    self.id_counter = IdCounter.new()
    self.characters = {}

    self.event_bus = services.event_bus as EventBus

    self.event_bus:on("INVENTORY_EQUIP_ITEM", function(ctx: MenuContext)
        self:handle_equip_item(ctx)
    end)
    self.event_bus:on("INVENTORY_UNEQUIP_ITEM", function(ctx: MenuContext)
        self:handle_unequip_item(ctx)
    end)
    self.event_bus:on("INVENTORY_DISCARD_ITEM", function(ctx: MenuContext)
        self:handle_discard_item(ctx)
    end)
end

function CharacterManager.new(): CharacterManager
    local self: CharacterManager = setmetatable({
        id = "character_manager",
        dependencies = {},
    }, { __index = CharacterManager})
    
    return self
end

return CharacterManager
