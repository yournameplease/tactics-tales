---@brief
--- A factory for creating new character instances from templates.
--- It handles the randomization of appearance attributes and the
--- initial setup of a character's inventory.

local character = require("src.tactics.character.object.character")
local sprite_data = require("src.tactics.character.sprite_data")
local randomizer = require("src.tactics.util.randomizer")
local random = require("src.tactics.util.random")
local ItemInventory = require("src.tactics.character.items.object.item_inventory")
local ItemGenerator = require("src.tactics.character.items.item_generator")
local NAMES = require("src.tactics.corpora.names")
local maps = require("src.tactics.util.maps")

local character_generator = {}

--- Build a Randomizer<string> from an AttributeOptions descriptor.
---@param options AttributeOptions
---@return table Randomizer instance for string values.
local function to_randomizer(options)
    if options.type == "list" then
        ---@cast options ListOptions
        return randomizer.weighted_option_selector.of(table.unpack(options.options))
    elseif options.type == "weighted" then
        ---@cast options WeightedOptions
        return randomizer.weighted_option_selector.of_weight_map(options.options)
    elseif options.type == "static" then
        ---@cast options StaticOption
        return randomizer.weighted_option_selector.of(options.option)
    else
        error("unexpected AttributeOptions type: " .. tostring(options.type))
    end
end

--- Merge a parent template with a child template, preferring child values.
---@param parent CharacterTemplate
---@param child CharacterTemplate
---@return CharacterTemplate
local function apply_template_to_parent(parent, child)
    ---@type CharacterTemplate
    local new_child = {
        movement = child.movement or parent.movement,
        hp_max = child.hp_max or parent.hp_max,
        item_loadout = child.item_loadout or parent.item_loadout,
        skill_loadout = child.skill_loadout or parent.skill_loadout,
        head_options_m = child.head_options_m or parent.head_options_m,
        head_options_f = child.head_options_f or parent.head_options_f,
        eyewear_options = child.eyewear_options or parent.eyewear_options,
        headwear_options = child.headwear_options or parent.headwear_options,
        body_options = child.body_options or parent.body_options,
        gender_options = child.gender_options or parent.gender_options,
        skin_color_options = child.skin_color_options or parent.skin_color_options,
        hair_color_options = child.hair_color_options or parent.hair_color_options,
        hair_options_m = child.hair_options_m or parent.hair_options_m,
        hair_options_f = child.hair_options_f or parent.hair_options_f,
        beard_options = child.beard_options or parent.beard_options,
        eye_options = child.eye_options or parent.eye_options,
    }
    return new_child
end

--- Recursively resolve a template ID to a fully-merged CharacterTemplate.
---@param template_id string? Template ID to resolve; nil uses "default".
---@param game_data table GameData containing the characters table.
---@return CharacterTemplate
local function build_template(template_id, game_data)
    if template_id == nil then
        return apply_template_to_parent({}, game_data.characters["default"])
    end

    local template_definition = game_data.characters[template_id]
    local template_parent = build_template(template_definition.parent_template, game_data)
    return apply_template_to_parent(template_parent, template_definition)
end

--- Generate a new Character from a template, randomising appearance and building inventory.
---@param id integer Unique character ID.
---@param template_id string? Template ID to generate from; nil uses "default".
---@param tags string[] List of string tags to assign.
---@param game_data table GameData containing character templates and item definitions.
---@return Character
function character_generator.generate_from_template(id, template_id, tags, game_data)
    log.debug("Generating from template ", template_id)
    local template = build_template(template_id, game_data)
    ---@diagnostic disable-next-line: missing-fields
    local char = { id = id, appearance = {}, stats = {} } ---@type Character

    char.stats.movement = template.movement
    char.stats.hp_max = template.hp_max
    char.stats.def = 0
    char.appearance.eyewear = to_randomizer(template.eyewear_options):pick_random()
    char.appearance.headwear = to_randomizer(template.headwear_options):pick_random()
    char.appearance.body_class = to_randomizer(template.body_options):pick_random()
    char.appearance.gender = to_randomizer(template.gender_options):pick_random()
    char.appearance.skin = to_randomizer(template.skin_color_options):pick_random()
    repeat
        char.appearance.hair_color = to_randomizer(template.hair_color_options):pick_random()
    until sprite_data.COLOR_NAMES[char.appearance.hair_color].color
        ~= sprite_data.SKIN_COLOR[char.appearance.skin].colors[1]
    if char.appearance.gender == "male" then
        char.appearance.head = to_randomizer(template.head_options_m):pick_random()
        char.appearance.hair = to_randomizer(template.hair_options_m):pick_random()
        char.appearance.beard = to_randomizer(template.beard_options):pick_random()
    else
        char.appearance.head = to_randomizer(template.head_options_f):pick_random()
        char.appearance.hair = to_randomizer(template.hair_options_f):pick_random()
        char.appearance.beard = "none"
    end
    char.appearance.eyes = to_randomizer(template.eye_options):pick_random()

    -- TODO: move these to a randomizer
    char.name = char.appearance.gender == "male"
        and random.choose_random_from_list(NAMES.MALE)
        or random.choose_random_from_list(NAMES.FEMALE)

    -- reduce size if inventory becomes meaningful
    char.inventory = ItemInventory.new(8)
    local item_ids = template.item_loadout or {}
    for i, item_id in ipairs(item_ids) do
        local generated_item = ItemGenerator.generate(item_id, game_data.items)
        if char.inventory:can_add_item(generated_item) then
            char.inventory:add_item(generated_item)
            if char.inventory:can_equip(i) then
                char.inventory:equip_item(i)
            end
        end
    end

    if char.appearance.gender == "female" and char.appearance.body_class == "shirtless" then
        char.appearance.body_class = "sleeveless"
    end

    char.skill_loadout = template.skill_loadout or {}

    char.tags = maps.set(tags) --[[@as table<string, boolean>]]

    return setmetatable(char, { __index = character.Character })
end

--- Reconstruct a Character from its serialized form, rebuilding the inventory.
---@param c SerializedCharacter The serialized character data.
---@param game_data table GameData containing item definitions.
---@return Character
function character_generator.deserialize(c, game_data)
    ---@type Character
    local self = setmetatable({
        id = c.id,
        name = c.name,
        appearance = c.appearance,
        stats = c.stats,
        tags = c.tags,
    }, { __index = character.Character })

    self.inventory = ItemInventory.new(8)
    local item_ids = c.inventory
    for i, item_id in ipairs(item_ids) do
        local generated_item = ItemGenerator.generate(item_id, game_data.items)
        if self.inventory:can_add_item(generated_item) then
            self.inventory:add_item(generated_item)
            if self.inventory:can_equip(i) then
                self.inventory:equip_item(i)
            end
        end
    end

    return self
end

return character_generator
