---@brief
--- Defines the data structures for character templates.
--- Specifies how character attributes and their randomization
--- options are structured.

---@alias AttributeDefinitionType "list"|"weighted"|"static"

--- Abstract base for all attribute option types.
---@class AttributeOptions
---@field type AttributeDefinitionType Discriminator for the option variant.
local AttributeOptions = {}

--- An attribute option that picks uniformly from a list of values.
---@class ListOptions : AttributeOptions
---@field type "list"
---@field options string[] Candidate values to pick from.
local ListOptions = {}

--- An attribute option that picks from values with explicit weights.
---@class WeightedOptions : AttributeOptions
---@field type "weighted"
---@field options table<string, integer> Map of value → relative weight.
local WeightedOptions = {}

--- An attribute option that always returns a single fixed value.
---@class StaticOption : AttributeOptions
---@field type "static"
---@field option string The fixed value returned.
local StaticOption = {}

--- Template describing how to generate a character of a given archetype.
---@class CharacterTemplate
---@field movement? integer Base movement range in tiles.
---@field hp_max? integer Maximum hit points.
---@field item_loadout? string[] Item IDs to add to the starting inventory.
---@field head_options_m? AttributeOptions Head shape options for male characters.
---@field head_options_f? AttributeOptions Head shape options for female characters.
---@field eyewear_options? AttributeOptions Eyewear accessory options.
---@field headwear_options? AttributeOptions Headwear accessory options.
---@field body_options? AttributeOptions Body class (shirt style) options.
---@field gender_options? AttributeOptions Gender options.
---@field skin_color_options? AttributeOptions Skin colour options.
---@field hair_color_options? AttributeOptions Hair colour options.
---@field hair_options_m? AttributeOptions Hair style options for male characters.
---@field hair_options_f? AttributeOptions Hair style options for female characters.
---@field beard_options? AttributeOptions Facial hair options.
---@field eye_options? AttributeOptions Eye shape options.
---@field parent_template? string ID of the template this one inherits from.
local CharacterTemplate = {}

return {
    AttributeOptions = AttributeOptions,
    ListOptions = ListOptions,
    WeightedOptions = WeightedOptions,
    StaticOption = StaticOption,
    CharacterTemplate = CharacterTemplate,
}
