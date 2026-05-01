---@brief
--- Manages the different UI contexts (battle, story, game) and provides
--- the correct, enriched context to the UI system.

require("src.tactics.ui.ui_context")
local battle_ui_context = require("src.tactics.battle.battle_ui_context")
local campaign_ui_context = require("src.tactics.campaign.campaign_ui_context")
local game_ui_context = require("src.tactics.game.game_ui_context")
require("src.tactics.ui.types")

---@class UIContextManager
---@field battle_context? BattleUIContext
---@field campaign_context? CampaignUIContext
---@field game_context? GameUIContext
---@field layout UILayoutId
local UIContextManager = {}
UIContextManager.__index = UIContextManager

local ui_context_manager = {
    UIContextManager = UIContextManager,
}

--- Create a new UIContextManager with the default TACTICS layout.
---@return UIContextManager
function ui_context_manager.new()
    ---@type UIContextManager
    local self = setmetatable({}, UIContextManager)
    self.layout = "TACTICS"
    return self
end

--- Register a UI context by type. Errors if that type is already registered.
---@param ctx UIContext
function UIContextManager:register_ui_context(ctx)
    if getmetatable(ctx) == battle_ui_context.BattleUIContext then
        assert(self.battle_context == nil, "Attempt to register battle context which was already registered!")
        ---@cast ctx BattleUIContext
        self.battle_context = ctx
    elseif getmetatable(ctx) == campaign_ui_context.CampaignUIContext then
        assert(self.campaign_context == nil, "Attempt to register game context which was already registered!")
        ---@cast ctx CampaignUIContext
        self.campaign_context = ctx
    elseif getmetatable(ctx) == game_ui_context.GameUIContext then
        assert(self.game_context == nil, "Attempt to register game context which was already registered!")
        ---@cast ctx GameUIContext
        self.game_context = ctx
    else
        error("Unexpexted UI Context: " .. ctx.type)
    end
end

--- Unregister the UI context of the given type. Errors if not registered.
---@param ctx_type UIContextType
function UIContextManager:unregister_ui_context(ctx_type)
    if ctx_type == "battle" then
        assert(self.battle_context ~= nil, "Attempt to unregister battle context which was not registered!")
        self.battle_context = nil
    end
    if ctx_type == "campaign" then
        assert(self.campaign_context ~= nil, "Attempt to unregister battle context which was not registered!")
        self.campaign_context = nil
    end
end

--- Enrich all registered contexts and update layout from the primary active context.
function UIContextManager:enrich()
    -- TODO: add a "NO_LAYOUT_FOUND"
    self.layout = "TITLE_SCREEN"

    if self.battle_context ~= nil then
        self.battle_context:enrich()
    end
    if self.campaign_context ~= nil then
        self.campaign_context:enrich()
    end
    if self.game_context ~= nil then
        self.game_context:enrich()
    end

    ---@type UIContext?
    local primary_context
    if self.battle_context ~= nil then
        primary_context = self.battle_context
    elseif self.campaign_context ~= nil then
        primary_context = self.campaign_context
    elseif self.game_context ~= nil then
        primary_context = self.game_context
    end

    if primary_context ~= nil then
        self.layout = primary_context.layout
    end
end

return ui_context_manager
