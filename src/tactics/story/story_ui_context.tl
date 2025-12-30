local ui_context = require("src/tactics/ui/ui_context")
local story_page = require("src/tactics/story/story_page")
local rendered_story_node = story_page.rendered_story_node
require("src/tactics/story/story_menu_manager")
local UILayoutId = require("src/tactics/ui/types").UILayoutId
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")

local record StoryUIContext
    is ui_context.UIContext
    where self.type == "story"

    story_page: StoryPage
    menu_manager: StoryMenuManager
end

local story_ui_context = {
    StoryUIContext = StoryUIContext
}

function story_ui_context.new(
    story_page: StoryPage,
    menu_manager: StoryMenuManager
): StoryUIContext
    local self: StoryUIContext = setmetatable({
        type = "story"
    }, { __index = StoryUIContext })

    self.story_page = story_page
    self.menu_manager = menu_manager

    return self
end

function StoryUIContext:enrich()
    self.layout = "STORY_PAGE"

    if self.menu_manager.menu_state.menu_id == "MENU_CUSTOMIZE_CHARACTER" then
        local cursor = self.menu_manager.menu_cursor
        assert(cursor is multiple_options_cursor.MultipleOptionsMenuCursor<StoryMenuContext>)
        local appearance: { CharacterAppearanceKey: integer} = {}
        for _,o in ipairs(cursor.options) do
            local option_cursor = o.cursor
            assert(option_cursor is list_cursor.ListMenuCursor<StoryMenuContext,integer>)

            local key = o.key 
            assert(key is CharacterAppearanceKey)
            appearance[key] = option_cursor.options[option_cursor.i].value
        end

        local character_customizer_node = self.story_page.nodes[#self.story_page.nodes]
            as rendered_story_node.CharacterCustomization -- lazy

        local drawable_character = character_customizer_node.character
        drawable_character.character.appearance = {}
        -- local any_change = false
        for k,a in pairs(appearance) do
            -- if drawable_character.character.appearance[k] ~= a then
                drawable_character.character.appearance[k] = a
                -- any_change = true
            -- end
        end
        -- if any_change then
            drawable_character.sprites = {}
        -- end
    end
end

return story_ui_context

