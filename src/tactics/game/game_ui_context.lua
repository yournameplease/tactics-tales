---@brief
--- Provides the UI context for the main game menus.

require("src.tactics.ui.layout.types")

---@class GameUIContext : UIContext
---@field type UIContextType
---@field input_service InputService
---@field menu_manager GameMenuManager
---@field event_bus EventBus
---@field menu_title string
---@field input_method InputMethod
---@field layout TacticsLayoutId
local GameUIContext = {}
GameUIContext.__index = GameUIContext

local game_ui_context = {
    GameUIContext = GameUIContext,
}

--- Create a new GameUIContext bound to the given bus, menu manager, and input service.
---@param bus EventBus
---@param menu_manager GameMenuManager
---@param input_service InputService
---@return GameUIContext
function game_ui_context.new(bus, menu_manager, input_service)
    ---@type GameUIContext
    local self = setmetatable({
        type = "game",
    }, GameUIContext)
    self.event_bus = bus
    self.menu_manager = menu_manager
    self.input_service = input_service
    return self
end

--- Populate derived display fields from current menu and input state.
function GameUIContext:enrich()
    self.input_method = self.input_service.current_input

    self.layout = "TITLED_MENU_PAGE"

    if self.menu_manager.menu_state.menu_id == "MENU_MAIN_MENU" then
        if self.menu_manager.menu_state.step == "TITLE_SCREEN" then
            self.layout = "TITLE_SCREEN"
        elseif self.menu_manager.menu_state.step == "MAIN_MENU" then
            self.menu_title = "Tactics Tales"
        elseif self.menu_manager.menu_state.step == "NEW_FILE_SELECT" then
            self.menu_title = "New File"
        elseif self.menu_manager.menu_state.step == "CONFIRM_FILE" then
            self.menu_title = "New File"
        elseif self.menu_manager.menu_state.step == "CAMPAIGN_CONFIG" then
            self.menu_title = "New File"
        elseif self.menu_manager.menu_state.step == "LOAD_FILE_SELECT" then
            self.menu_title = "Load File"
        elseif self.menu_manager.menu_state.step == "CHAPTER_SELECT" then
            self.menu_title = "Chapters"
        elseif self.menu_manager.menu_state.step == "OPTIONS_MENU" then
            self.menu_title = "Options"
        else
            error("unexpected menu state")
        end
    end
end

return game_ui_context
