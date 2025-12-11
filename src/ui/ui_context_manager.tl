require("src/ui/types")
require("src/systems/service")
require("src/battle/battle_ui_context")
require("src/story/story_ui_context")

global type UILayoutId

global record UIContextManager
    is TransientGameService
    where self.id == 'ui_context_manager'
    
    service_manager: ServiceManager

    battle_ui_context: BattleUIContext
    story_ui_context: StoryUIContext

    layout: UILayoutId
    
end

function UIContextManager:init(_service_manager: ServiceManager, services: { ServiceId: GameService })
    self.layout = "TACTICS"

    self.service_manager = services.service_manager as ServiceManager
end

function UIContextManager.new(): UIContextManager
    local context: UIContextManager = setmetatable({
        id = "ui_context_manager",
        dependencies = {
            "service_manager",
        }
    }, { __index = UIContextManager })
    return context
end

function UIContextManager:enrich()
    self.layout = "TACTICS"

    -- find and enrich contexts
    self.battle_ui_context = self.service_manager.transient_services.battle_ui_context as BattleUIContext
    if self.battle_ui_context ~= nil then
        self.battle_ui_context:enrich()
    end

    self.story_ui_context = self.service_manager.transient_services.story_ui_context as StoryUIContext
    if self.story_ui_context ~= nil then
        self.story_ui_context:enrich()
    end

    -- pick layout from contexts

    if self.battle_ui_context ~= nil then
        self.layout = self.battle_ui_context.layout
        LOG.debug("yes battle ui context")
    elseif self.story_ui_context ~= nil then
        self.layout = self.story_ui_context.layout
    end
end

return UIContextManager
