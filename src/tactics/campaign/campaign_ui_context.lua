---@brief
--- Provides the UI context for campaign scenes, giving the UI rendering
--- system access to the current campaign state.

require("src.tactics.ui.ui_context")
require("src.tactics.campaign.campaign_page")
require("src.tactics.menu.menu_manager")

---@class CampaignUIContext : UIContext
---@field type "campaign"
---@field campaign_page CampaignPage
---@field menu_manager MenuManager
local CampaignUIContext = {}
CampaignUIContext.__index = CampaignUIContext

local campaign_ui_context = {
    CampaignUIContext = CampaignUIContext,
}

--- Create a new CampaignUIContext for the given campaign page and menu manager.
---@param page CampaignPage
---@param menu_manager MenuManager
---@return CampaignUIContext
function campaign_ui_context.new(page, menu_manager)
    ---@type CampaignUIContext
    local self = setmetatable({
        type = "campaign",
    }, CampaignUIContext)

    self.campaign_page = page
    self.menu_manager = menu_manager

    return self
end

--- Enrich the context with layout and live character appearance data.
function CampaignUIContext:enrich()
    self.layout = "CAMPAIGN_PAGE"

    local menu = self.menu_manager:serialize()

    if menu.menu_id == "MENU_CUSTOMIZE_CHARACTER" and menu.node ~= nil then
        ---@type table<string, string>
        local appearance = menu.node.data

        local character_customizer_node = self.campaign_page.nodes
        [#self.campaign_page.nodes] --[[@as RenderedCharacterCustomization]]

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

return campaign_ui_context
