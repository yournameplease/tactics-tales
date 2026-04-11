---@brief
--- Provides the UI context for story scenes, giving the UI rendering
--- system access to the current story state.

require("src.tactics.ui.ui_context")
require("src.tactics.story.story_page")
require("src.tactics.menu.menu_manager")

---@class StoryUIContext : UIContext
---@field type "story"
---@field story_page StoryPage
---@field menu_manager MenuManager
local StoryUIContext = {}
StoryUIContext.__index = StoryUIContext

local story_ui_context = {
    StoryUIContext = StoryUIContext,
}

--- Create a new StoryUIContext for the given story page and menu manager.
---@param page StoryPage
---@param menu_manager MenuManager
---@return StoryUIContext
function story_ui_context.new(page, menu_manager)
    ---@type StoryUIContext
    local self = setmetatable({
        type = "story",
    }, StoryUIContext)

    self.story_page = page
    self.menu_manager = menu_manager

    return self
end

--- Enrich the context with layout and live character appearance data.
function StoryUIContext:enrich()
    self.layout = "STORY_PAGE"

    local menu = self.menu_manager:serialize()

    if menu.menu_id == "MENU_CUSTOMIZE_CHARACTER" and menu.node ~= nil then
        ---@type table<string, string>
        local appearance = menu.node.data

        local character_customizer_node = self.story_page.nodes[#self.story_page.nodes] --[[@as RenderedCharacterCustomization]]

        local drawable_character = character_customizer_node.character
        if drawable_character ~= nil then
            ---@diagnostic disable-next-line: missing-fields
            drawable_character.character.appearance = {}
            local any_change = false
            for k, a in pairs(appearance) do
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
end

return story_ui_context
