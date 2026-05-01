---@brief
--- Defines the context object for menus used within story scenes.

---@class StoryMenuServices : GameContext
---@field character_appearance table<string, string> Map from CharacterAppearanceKey to current value.
---@field handle_create_character fun(appearance: table<string, string>) Callback invoked when the player confirms character creation.
---@field handle_submit_text fun(text: string) Callback invoked when the player submits text input.
---@field selection_options SelectOptionEntry[] Options for the active select_option node; set by the node handler before opening the menu.
---@field handle_select_option fun(option_id: string) Callback invoked when the player confirms an option selection.
local StoryMenuServices = {}
StoryMenuServices.__index = StoryMenuServices

local campaign_menu_context = {
    CampaignMenuContext = StoryMenuServices,
}

--- Create a new story menu context with the given callbacks.
---@param handle_create_character fun(appearance: table<string, string>)
---@param handle_submit_text fun(text: string)
---@param handle_select_option fun(option_id: string)
---@return StoryMenuServices
function campaign_menu_context.new(handle_create_character, handle_submit_text, handle_select_option)
    ---@type StoryMenuServices
    local self = setmetatable({}, StoryMenuServices)
    self.handle_create_character = handle_create_character
    self.handle_submit_text = handle_submit_text
    self.handle_select_option = handle_select_option
    return self
end

return campaign_menu_context
