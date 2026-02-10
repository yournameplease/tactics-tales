---@brief
--- Provides the UI context for story scenes, giving the UI rendering
--- system access to the current story state.

local ui_context = require("src.tactics.ui.ui_context")
local story_page = require("src.tactics.story.story_page")
local rendered_story_node = story_page.rendered_story_node
local StoryMenuContext = require("src.tactics.story.story_menu_context").StoryMenuContext
local story_menu_manager = require("src.tactics.story.story_menu_manager")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local character = require("src.tactics.character.object.character")

local record StoryUIContext
    is ui_context.UIContext
    where self.type == "story"

    story_page: story_page.StoryPage
    menu_manager: story_menu_manager.StoryMenuManager
end

local story_ui_context = {
    StoryUIContext = StoryUIContext
}

function story_ui_context.new(
    page: story_page.StoryPage,
    menu_manager: story_menu_manager.StoryMenuManager
): StoryUIContext
    local self: StoryUIContext = setmetatable({
        type = "story"
    }, { __index = StoryUIContext })

    self.story_page = page
    self.menu_manager = menu_manager

    return self
end

function StoryUIContext:enrich()
    self.layout = "STORY_PAGE"

    if self.menu_manager.menu_state.menu_id == "MENU_CUSTOMIZE_CHARACTER" then
        local cursor = self.menu_manager.menu_cursor
        assert(cursor is multiple_options_cursor.MultipleOptionsMenuNode)
        local appearance: { character.CharacterAppearanceKey: string} = {}
        for _,o in ipairs(cursor.options) do
            local option_cursor = o.cursor
            assert(option_cursor is list_cursor.ListMenuNode<string>)

            local key = o.key 
            assert(key is character.CharacterAppearanceKey)
            appearance[key] = option_cursor.options[option_cursor.i].value
        end

        local character_customizer_node = self.story_page.nodes[#self.story_page.nodes]
            as rendered_story_node.CharacterCustomization -- lazy

        local drawable_character = character_customizer_node.character
        if drawable_character ~= nil then
            drawable_character.character.appearance = {}
        end
        local any_change = false
        for k,a in pairs(appearance) do
            if drawable_character.character.appearance[k] ~= a then
                drawable_character.character.appearance[k] = a
                any_change = true
            end
        end
        if any_change then
            drawable_character.sprites = {}
        end
    end
end

return story_ui_context

