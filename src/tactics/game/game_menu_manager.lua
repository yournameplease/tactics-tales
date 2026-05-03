---@brief
--- Manages the main game menu, including the title screen,
--- chapter select, and options menus.

local lists = require("src.tactics.util.lists")
local menu_manager = require("src.tactics.menu.menu_manager")
local menu_handler = menu_manager.menu_handler
local step_definition = menu_manager.definition.step
local list = require("src.tactics.menu.cursor.nested.list")
local button = require("src.tactics.menu.cursor.button")
local selection = require("src.tactics.menu.cursor.selection")

---@class GameMenuManager : MenuManager

local game_menu_manager = {}

---@class MainMenuContext : MenuContext
---@field selected_file string The save file name chosen by the player for overwrite confirmation.

---@type table<string, MenuHandler<GameMenuContext, MainMenuContext>>
local HANDLERS = {}

--- Advance from the title screen: go to main menu, or auto-start the default campaign in demo mode.
---@param services GameMenuContext
---@param _menu_data table<string, any>
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
function HANDLERS.title_advance(services, _menu_data, _session_context, _value)
    if not DYNAMIC_CONFIG.demo_mode then
        return menu_handler.then_navigate("MAIN_MENU")
    end
    local def = services.campaigns[services.default_campaign_id]
    local config = {}
    if def and def.config and def.config.default_preset and def.config.presets then
        for _, p in ipairs(def.config.presets) do
            if p.key == def.config.default_preset then
                for k, v in pairs(p.values) do config[k] = v end
                break
            end
        end
    end
    services.handle_begin_campaign(nil, services.default_campaign_id, config)
    return nil
end

--- Store the selected save file name in session context for the overwrite confirmation step.
---@param _services GameMenuContext
---@param _menu_data table<string, any>
---@param session_context MainMenuContext
---@param file CampaignId
---@return MenuHandlerPostHandling?
function HANDLERS.store_selected_save(_services, _menu_data, session_context, file)
    session_context.selected_file = file
    return nil
end

--- Begin a campaign using the file name stored in session context.
---@param services GameMenuContext
---@param menu_data table<string, string>
---@param session_context MainMenuContext
---@param _value string
---@return MenuHandlerPostHandling?
function HANDLERS.begin_file_from_context(services, menu_data, session_context, _value)
    local config = {}
    for k, v in pairs(menu_data) do
        if k ~= "_preset" then config[k] = v end
    end
    services.handle_begin_campaign(session_context.selected_file, services.default_campaign_id, config)
    return nil
end

--- Apply a preset to all option values when the preset row changes.
---@param services GameMenuContext
---@param _menu_data table<string, any>
---@param _ctx MainMenuContext
---@param value string
---@return MenuHandlerPostHandling
function HANDLERS.apply_preset(services, _menu_data, _ctx, value)
    if value == "custom" then
        return nil
    end
    local config = services.campaigns[services.default_campaign_id].config
    local data = { _preset = value }
    for _, p in ipairs(config.presets) do
        if p.key == value then
            for k, v in pairs(p.values) do data[k] = v end
        end
    end
    return menu_handler.then_deserialize(data)
end

--- Sync the preset row to "custom" or a matching preset key after an option changes.
---@param services GameMenuContext
---@param menu_data table<string, any>
---@param _ctx MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling
function HANDLERS.sync_preset_from_options(services, menu_data, _ctx, _value)
    local config = services.campaigns[services.default_campaign_id].config
    local matched = "custom"
    if config and config.presets then
        for _, p in ipairs(config.presets) do
            local match = true
            for k, v in pairs(p.values) do
                if menu_data[k] ~= v then match = false; break end
            end
            if match then matched = p.key; break end
        end
    end
    local data = {}
    for k, v in pairs(menu_data) do data[k] = v end
    data._preset = matched
    return menu_handler.then_deserialize(data)
end

--- Load an existing campaign save by file name.
---@param services GameMenuContext
---@param _menu_data table<string, any>
---@param _session_context MainMenuContext
---@param file CampaignId
---@return MenuHandlerPostHandling?
function HANDLERS.load_campaign(services, _menu_data, _session_context, file)
    services.handle_load_campaign(file)
    return nil
end

--- Begin a campaign chapter directly by campaign ID.
---@param services GameMenuContext
---@param _menu_data table<string, any>
---@param _session_context MainMenuContext
---@param campaign_id CampaignId
---@return MenuHandlerPostHandling?
function HANDLERS.begin_chapter(services, _menu_data, _session_context, campaign_id)
    services.handle_begin_campaign(nil, campaign_id, {}) -- TODO: Config?  Or default config?
    return nil
end

--- Persist the current options menu data to config.
---@param services GameMenuContext
---@param menu_data DynamicConfig
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
function HANDLERS.set_options(services, menu_data, _session_context, _value)
    services.config_manager:store_config(menu_data)
    return nil
end

--- Reset config to defaults.
---@param services GameMenuContext
---@param _menu_data DynamicConfig
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
function HANDLERS.reset_options(services, _menu_data, _session_context, _value)
    services.config_manager:reset_config()
    return nil
end

--- Apply glyph family immediately without persisting.
---@param services GameMenuContext
---@param menu_data DynamicConfig
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
function HANDLERS.apply_glyph_family(services, menu_data, _session_context, _value)
    services.config_manager:apply_glyph_family(menu_data.glyph_family)
    return nil
end

--- Apply volume settings immediately without persisting.
---@param services GameMenuContext
---@param menu_data DynamicConfig
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
function HANDLERS.apply_volume(services, menu_data, _session_context, _value)
    services.config_manager:apply_volume(
        menu_data.master_volume,
        menu_data.music_volume,
        menu_data.sfx_volume
    )
    return nil
end

---@param dest string
---@return table
local function nav_back(dest)
    return list.row("options_navigation", function(_msb, _ctx)
        return { button.builder("back"):with_text("Back"):advance_to(dest) }
    end)
end

---@type table<string, MenuDefinition>
local MENU_DATA = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        handlers = HANDLERS,
        steps = {
            ["TITLE_SCREEN"] = step_definition.of_node(
                button.builder("to_main_menu")
                :with_text("Main Menu")
                :handle_action("select", "title_advance")
            )
            :with_default_lmb("select")
            :with_action("BUTTON_A", { command = "select", description = "Start"}),
            ["MAIN_MENU"] = step_definition.of_node(
                list.column(
                    "main_menu",
                    function(_msb, _ctx)
                        local options = {}

                        table.insert(options, button.builder("begin_campaign")
                            :with_text("New Game")
                            :advance_to("NEW_FILE_SELECT"))
                        table.insert(options, button.builder("load_campaign")
                            :with_text("Load Game")
                            :advance_to("LOAD_FILE_SELECT"))
                        table.insert(options, button.builder("to_chapter_select")
                            :with_text("Chapter Select")
                            :advance_to("CHAPTER_SELECT"))
                        table.insert(options, button.builder("to_options")
                            :with_text("Options")
                            :advance_to("OPTIONS_MENU"))

                        return options
                    end
                )
            )
            :with_previous_step("TITLE_SCREEN")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["NEW_FILE_SELECT"] = step_definition.of_node(
                list.column(
                    "new_file_select",
                    function(msb, _ctx)
                        ---@cast msb GameMenuContext
                        local options = {}
                        local existing_files = msb.get_game_saves()

                        for i = 1, 5 do
                            local file_name = "file_" .. i
                            local b = button.builder(file_name)
                                :with_text("File " .. i)
                                :with_value(file_name)

                            if lists.contains(existing_files, file_name) then
                                b = b:handle_action("select", "store_selected_save")
                                    :advance_to("CONFIRM_FILE")
                            else
                                b = b:handle_action("select", "store_selected_save")
                                    :advance_to("CAMPAIGN_CONFIG")
                            end
                            table.insert(options, b)
                        end

                        table.insert(options, nav_back("MAIN_MENU"))
                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["CONFIRM_FILE"] = step_definition.of_node(
                list.column(
                    "confirm_file",
                    function(_msb, ctx)
                        ---@cast ctx MainMenuContext
                        local options = {}

                        table.insert(options, button.builder("label")
                            :with_text("Confirm overwrite " .. ctx.selected_file .. "?"))
                        table.insert(options, button.builder("confirm_overwrite")
                            :with_text("Confirm")
                            :advance_to("CAMPAIGN_CONFIG"))
                        table.insert(options, button.builder("no_overwrite")
                            :advance_to("NEW_FILE_SELECT")
                            :with_text("Back"))

                        return options
                    end
                )
            )
            :with_previous_step("NEW_FILE_SELECT")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["LOAD_FILE_SELECT"] = step_definition.of_node(
                list.column(
                    "load_file_select",
                    function(msb, _ctx)
                        ---@cast msb GameMenuContext
                        local options = {}
                        local existing_files = msb.get_game_saves()

                        for _, file_name in ipairs(existing_files) do
                            local b = button.builder(file_name)
                                :with_text(file_name)
                                :with_value(file_name)
                                :handle_action("select", "load_campaign")

                            table.insert(options, b)
                        end

                        table.insert(options, nav_back("MAIN_MENU"))
                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["CAMPAIGN_CONFIG"] = step_definition.of_node(
                list.column(
                    "confirm_file",
                    function(msb, ctx)
                        ---@cast msb GameMenuContext
                        ---@cast ctx MainMenuContext
                        local options = {}

                        local campaign_id = msb.default_campaign_id
                        local definition = msb.campaigns[campaign_id]
                        local config = definition.config

                        if config then
                            if config.presets then
                                local preset_row = selection.row("_preset")
                                    :with_key("_preset")
                                    :with_label("Difficulty")
                                    :with_on_change("apply_preset")
                                for _, p in ipairs(config.presets) do
                                    preset_row = preset_row:with_static_option{ value = p.key, text = p.name }
                                end
                                preset_row = preset_row:with_static_option{ value = "custom", text = "Custom" }
                                table.insert(options, preset_row)
                            end

                            for _, opt in ipairs(config.options) do
                                local b = selection.row(opt.key)
                                    :with_key(opt.key)
                                    :with_label(opt.name)
                                    :with_description(opt.description)
                                    :with_on_change("sync_preset_from_options")

                                for _,o in ipairs(opt.options) do
                                    b = b:with_static_option{
                                        value = o.value,
                                        text = o.name,
                                        description = o.description,
                                    }
                                end

                                table.insert(options, b)
                            end
                        end

                        table.insert(options, button.builder("confirm_begin")
                            :with_text("Begin")
                            :handle_action("select", "begin_file_from_context")
                            :as_final_step())
                        table.insert(options, button.builder("no_begin")
                            :advance_to("NEW_FILE_SELECT")
                            :with_text("Back"))

                        return options
                    end
                )
            )
            :with_previous_step("NEW_FILE_SELECT")
            :with_initial_data(function(msb, _ctx)
                ---@cast msb GameMenuContext
                local def = msb.campaigns[msb.default_campaign_id]
                local config = def and def.config
                if not config or not config.presets or not config.default_preset then return {} end
                local preset_key = config.default_preset
                local data = { _preset = preset_key }
                for _, p in ipairs(config.presets) do
                    if p.key == preset_key then
                        for k, v in pairs(p.values) do data[k] = v end
                    end
                end
                return data
            end)
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["CHAPTER_SELECT"] = step_definition.of_node(
                list.column(
                    "chapter_select",
                    function(msb, _ctx)
                        ---@cast msb GameMenuContext
                        local options = {}

                        for _, campaign_id in ipairs(msb.campaign_ids) do
                            local def = msb.campaigns[campaign_id]
                            table.insert(options, button.builder("begin_campaign_" .. campaign_id)
                                :with_text(def.name)
                                :with_description(def.description)
                                :with_value(campaign_id)
                                :handle_action("select", "begin_chapter"))
                        end

                        table.insert(options, nav_back("MAIN_MENU"))
                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["OPTIONS_MENU"] = step_definition.of_node(
                list.column(
                    "options_menu",
                    function(_msb, _ctx)
                        local children = {}

                        table.insert(children, list.column(
                            "options_selections",
                            function(_msb2, _ctx2)
                                local options = {}
                                table.insert(options, selection.row("log_level")
                                    :with_label("Log Level")
                                    :with_key("log_level")
                                    :with_static_option_flat("ERROR")
                                    :with_static_option_flat("WARNING")
                                    :with_static_option_flat("INFO")
                                    :with_static_option_flat("DEBUG")
                                    :with_static_option_flat("TRACE"))
                                table.insert(options, selection.row("draw_flexbox_debug")
                                    :with_label("Draw Flexbox Debug")
                                    :with_key("draw_flexbox_debug")
                                    :with_description("")
                                    :with_static_option_flat(true, "YES")
                                    :with_static_option_flat(false, "NO"))
                                table.insert(options, selection.row("profile")
                                    :with_label("Profiler")
                                    :with_key("profile")
                                    :with_description("")
                                    :with_static_option_flat(true, "YES")
                                    :with_static_option_flat(false, "NO"))
                                table.insert(options, selection.row("head_scale")
                                    :with_label("Head Scale")
                                    :with_key("head_scale")
                                    :with_description("")
                                    :with_static_option_flat(1, "Normal")
                                    :with_static_option_flat(2, "Large")
                                    :with_static_option_flat(3, "Huge")
                                    :with_static_option_flat(0.75, "Small")
                                    :with_static_option_flat(0, "Headless"))
                                table.insert(options, selection.row("dialogue_speed")
                                    :with_label("Text Speed")
                                    :with_key("dialogue_speed")
                                    :with_description("")
                                    :with_static_option_flat("very_slow", "Very Slow")
                                    :with_static_option_flat("slow", "Slow")
                                    :with_static_option_flat("normal", "Normal")
                                    :with_static_option_flat("fast", "Fast")
                                    :with_static_option_flat("very_fast", "Very Fast")
                                    :with_static_option_flat("instant", "Instant"))
                                table.insert(options, selection.row("glyph_family")
                                    :with_label("Glyphs")
                                    :with_key("glyph_family")
                                    :with_description("Glyphs to display for joypad inputs")
                                    :with_static_option_flat("keyboard", "Keyboard")
                                    :with_static_option_flat("picotron", "Picotron")
                                    :with_static_option_flat("snes", "SNES")
                                    :with_static_option_flat("nintendo", "Nintendo")
                                    :with_static_option_flat("xbox", "Xbox")
                                    :with_static_option_flat("playstation", "PlayStation")
                                    :with_on_change("apply_glyph_family"))
                                table.insert(options, selection.row("input_group")
                                    :with_label("Input Mode")
                                    :with_key("input_group")
                                    :with_description("Limit to specific input modes")
                                    :with_static_option_flat("mouse_and_keyboard", "Mouse and Joypad", "Allows either mouse or joypad (including keyboard)")
                                    :with_static_option_flat("mouse_only", "Mouse Only", "Mouse controls only")
                                    :with_static_option_flat("joy_only", "Joypad Only", "Joypad/keyboard controls only"))
                                table.insert(options, selection.row("master_volume")
                                    :with_label("Master Volume")
                                    :with_key("master_volume")
                                    :with_static_options({0,1,2,3,4,5,6,7,8,9,10})
                                    :with_on_change("apply_volume"))
                                table.insert(options, selection.row("music_volume")
                                    :with_label("Music Volume")
                                    :with_key("music_volume")
                                    :with_static_options({0,1,2,3,4,5,6,7,8,9,10})
                                    :with_on_change("apply_volume"))
                                table.insert(options, selection.row("sfx_volume")
                                    :with_label("SFX Volume")
                                    :with_key("sfx_volume")
                                    :with_static_options({0,1,2,3,4,5,6,7,8,9,10})
                                    :with_on_change("apply_volume"))
                                return options
                            end))

                        table.insert(children, list.row(
                            "options_navigation",
                            function(_msb2, _ctx2)
                                local options = {}
                                table.insert(options, button.builder("back")
                                    :with_text("Back")
                                    :advance_to("MAIN_MENU"))
                                table.insert(options, button.builder("reset")
                                    :with_text("Defaults")
                                    :handle_action("select", "reset_options")
                                    :advance_to("MAIN_MENU"))
                                table.insert(options, button.builder("save")
                                    :with_text("Save")
                                    :handle_action("select", "set_options")
                                    :advance_to("MAIN_MENU"))
                                return options
                            end))

                        return children
                    end
                )
            ):with_initial_data(function(_services, _session_data)
                return DYNAMIC_CONFIG
            end)
            :with_action("BUTTON_A", { command = "select", description = "Select"}),
        }
    }
}

--- Create a new GameMenuManager for the main game menu.
---@param ctx GameMenuContext
---@param bus EventBus
---@return GameMenuManager
function game_menu_manager.new(ctx, bus)
    return menu_manager.new(
        MENU_DATA,
        ctx,
        bus
    ) --[[@as GameMenuManager]]
end

return game_menu_manager
