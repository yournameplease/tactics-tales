---@brief
--- Manages menus that appear during story sequences, such as
--- the character customization screen.

local random = require("src.tactics.util.random")
local sprite_data = require("src.tactics.character.sprite_data")
local customization_options = sprite_data.customization_options
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local list = require("src.tactics.menu.cursor.nested.list")
local maps = require("src.tactics.util.maps")
local button = require("src.tactics.menu.cursor.button")
local menu_keyboard = require("src.tactics.menu.on_screen_keyboard")
local selection = require("src.tactics.menu.cursor.selection")
local lists = require("src.tactics.util.lists")

--- Build a random appearance table with all customization keys filled.
---@return table<string, string>
local function random_appearance()
    return {
        ["head"]       = random.choose_random_from_list(customization_options.HEAD),
        ["hair"]       = random.choose_random_from_list(customization_options.HAIR),
        ["skin"]       = random.choose_random_from_list(customization_options.SKIN_COLOR),
        ["hair_color"] = random.choose_random_from_list(customization_options.HAIR_COLOR),
        ["body_class"] = random.choose_random_from_list(customization_options.BODY_CLASS),
        ["beard"]      = random.choose_random_from_list(customization_options.FACIAL_HAIR),
        ["eyes"]       = random.choose_random_from_list(customization_options.EYES),
        ["eyewear"]    = random.choose_random_from_list(customization_options.EYEWEAR),
        ["headwear"]   = random.choose_random_from_list(customization_options.HEADWEAR),
    }
end

--- Convert a list of (id, NamedSpriteData) pairs into a SelectionMenuOption list.
---@param options table[] Each entry is a two-element array {id, NamedSpriteData}.
---@return SelectionMenuOption[]
local function list_cursor_options_for_part(options)
    local cursor_options = lists.map(function(option)
        return {
            text  = option[2].name,
            value = option[1],
        }
    end)(options)
    return cursor_options
end

--- Build a SelectionMenuDefinition for a single character appearance part.
---@param key string CharacterAppearanceKey identifying the part.
---@param text string Label to display for this selection row.
---@param options string[] Ordered list of valid option IDs.
---@param data table<string, NamedSpriteData> Map from option ID to sprite data.
---@return SelectionMenuDefinition
local function multiple_option_cursor_for_part(key, text, options, data)
    local data_list = lists.map(function(id)
        return { id, data[id] }
    end)(options)

    return selection.row(key .. "_selection")
            :with_label(text)
            :with_key(key)
            :with_wrap(true)
            :with_precomputed_options(list_cursor_options_for_part(data_list))
end

--- Build the MenuStepDefinition for the character customization selection screen.
---@return MenuStepDefinition
local function menu_definition_for_character_select()
    return step_definition.of_node(
        list.column(
            "character_creation_menu",
            function(_msb, _ctx)
                local children = {}
                table.insert(children, list.column(
                    "appearance_selections",
                    function(_msb2, _ctx2)
                        local options = {
                            multiple_option_cursor_for_part("head",       "Head",        customization_options.HEAD,        sprite_data.HEAD),
                            multiple_option_cursor_for_part("hair",       "Hair",        customization_options.HAIR,        sprite_data.HAIR),
                            multiple_option_cursor_for_part("skin",       "Skin Color",  customization_options.SKIN_COLOR,  sprite_data.SKIN_COLOR),
                            multiple_option_cursor_for_part("hair_color", "Hair Color",  customization_options.HAIR_COLOR,  sprite_data.COLOR_NAMES),
                            multiple_option_cursor_for_part("body_class", "Body",        customization_options.BODY_CLASS,  sprite_data.BODY_CLASS),
                            multiple_option_cursor_for_part("beard",      "Facial Hair", customization_options.FACIAL_HAIR, sprite_data.FACIAL_HAIR),
                            multiple_option_cursor_for_part("eyes",       "Eyes",        customization_options.EYES,        sprite_data.EYES),
                            multiple_option_cursor_for_part("eyewear",    "Eyewear",     customization_options.EYEWEAR,     sprite_data.EYEWEAR),
                            multiple_option_cursor_for_part("headwear",   "Headwear",    customization_options.HEADWEAR,    sprite_data.HEADWEAR),
                        }
                        return options
                    end))

                table.insert(children, list.row(
                    "character_creation",
                    function(_msb3, _ctx3)
                        local options = {}
                        table.insert(options, button.builder("randomize")
                            :with_text("Randomize")
                            :handle_action("select", "randomize_appearance"))
                        table.insert(options, button.builder("confirm")
                            :with_text("Confirm")
                            :handle_action("select", "create_character"))
                        return options
                    end))

                return children
            end))
            :with_initial_data(function(services, _session_data)
                ---@cast services StoryMenuServices
                if services.character_appearance then
                    return services.character_appearance
                end
                return {}
            end)
            :with_action("BUTTON_A", { command = "select", description = "Select" })
end

---@type table<string, MenuHandler>
local HANDLERS = {}

HANDLERS["randomize_appearance"] = function(_services, _menu_data, _session_context, _value)
    return menu_manager.menu_handler.then_deserialize(random_appearance())
end

HANDLERS["create_character"] = function(services, menu_data, _session_context, _value)
    ---@cast services StoryMenuServices
    services.handle_create_character(menu_data)
    return nil
end

HANDLERS["submit_text"] = function(services, _menu_data, session_context, _value)
    ---@cast services StoryMenuServices
    ---@cast session_context KeyboardMenuContext
    services.handle_submit_text(session_context.keyboard_content)
    return nil
end

maps.add_all(HANDLERS, menu_keyboard.handlers)

---@type table<string, MenuDefinition>
local MENU_DATA = {
    ["MENU_CUSTOMIZE_CHARACTER"] = {
        initial_step = "APPEARANCE_OPTIONS",
        steps = {
            ["APPEARANCE_OPTIONS"] = menu_definition_for_character_select(),
        }
    },
    ["MENU_TEXT_INPUT"] = {
        initial_step = "KEYBOARD",
        steps = {
            ["KEYBOARD"] = menu_keyboard.step("submit_text"),
        }
    },
}

local story_menu_manager = {}

--- Create a new MenuManager configured for story sequences.
---@param ctx StoryMenuServices
---@param bus EventBus
---@return MenuManager
function story_menu_manager.new(ctx, bus)
    return menu_manager.new(MENU_DATA, HANDLERS, ctx, bus)
end

return story_menu_manager
