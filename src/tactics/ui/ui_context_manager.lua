---@brief
--- Game-side glue around the engine UIContextStack. Declares the
--- tactics-specific context nesting (battle on top of campaign on top
--- of game menus) and the typed view that game code reads from.

local ui_context_stack = require("src.tactics.ui.ui_context_stack")
require("src.tactics.battle.battle_ui_context")
require("src.tactics.campaign.campaign_ui_context")
require("src.tactics.game.game_ui_context")
require("src.tactics.ui.layout.types")

---@class UIContextManager : UIContextStack
---@field battle_context? BattleUIContext
---@field campaign_context? CampaignUIContext
---@field game_context? GameUIContext
---@field layout TacticsLayoutId

local ui_context_manager = {}

--- Create a new UIContextManager wired with the tactics context priority.
---@return UIContextManager
function ui_context_manager.new()
    return ui_context_stack.new({
        layout_priority = { "battle", "campaign", "game" },
        default_layout = "TITLE_SCREEN",
    }) --[[@as UIContextManager]]
end

return ui_context_manager
