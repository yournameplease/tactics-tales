local event_bus = require("src.tactics.systems.event_bus")
local ui_context = require("src.tactics.ui.ui_context")
local UILayoutId = require("src.tactics.ui.types").UILayoutId
local GameMenuManager = require("src.tactics.game.game_menu_manager").GameMenuManager
local input_srv = require("src.tactics.joypad")
local InputService = input_srv.InputService
local InputMethod = input_srv.InputMethod

local record GameUIContext
    is ui_context.UIContext
    where self.type == "game"

    input_service: InputService
    menu_manager: GameMenuManager
    event_bus: event_bus.EventBus

    input_method: InputMethod
    
    layout: UILayoutId
end

local game_ui_context = {
    GameUIContext = GameUIContext
}

function game_ui_context.new(bus: event_bus.EventBus, menu_manager: GameMenuManager, input_service: InputService): GameUIContext
    local self: GameUIContext = setmetatable({
        type = "game"
    }, { __index = GameUIContext })

    self.event_bus = bus
    self.menu_manager = menu_manager
    self.input_service = input_service
    
    return self
end

function GameUIContext:enrich()
    self.input_method = self.input_service.current_input
    
    self.layout = "TITLE_SCREEN"

    if self.menu_manager.menu_state.menu_id == "MENU_MAIN_MENU" then
        if self.menu_manager.menu_state.step == "TITLE_SCREEN" then
            self.layout = "TITLE_SCREEN"
        elseif self.menu_manager.menu_state.step == "MAIN_MENU" then
            self.layout = "MAIN_MENU_PAGE"
        elseif self.menu_manager.menu_state.step == "CHAPTER_SELECT" then
            self.layout = "CHAPTER_SELECT_PAGE"
        elseif self.menu_manager.menu_state.step == "OPTIONS_MENU" then
            self.layout = "OPTIONS_MENU_PAGE"
        else
            error("unexpected menu state")
        end
    end
end

return game_ui_context

