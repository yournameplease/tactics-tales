---@brief
--- Defines the context object for menus used within story scenes.

---@class StoryMenuServices : GameContext
---@field character_appearance table<string, string> Map from CharacterAppearanceKey to current value.
---@field handle_create_character fun(appearance: table<string, string>) Callback invoked when the player confirms character creation.
---@field handle_submit_text fun(text: string) Callback invoked when the player submits text input.
local StoryMenuServices = {}
StoryMenuServices.__index = StoryMenuServices

local story_menu_context = {
    StoryMenuContext = StoryMenuServices,
}

--- Create a new story menu context with the given callbacks.
---@param handle_create_character fun(appearance: table<string, string>)
---@param handle_submit_text fun(text: string)
---@return StoryMenuServices
function story_menu_context.new(handle_create_character, handle_submit_text)
    ---@type StoryMenuServices
    local self = setmetatable({}, StoryMenuServices)
    self.handle_create_character = handle_create_character
    self.handle_submit_text = handle_submit_text
    return self
end

return story_menu_context
