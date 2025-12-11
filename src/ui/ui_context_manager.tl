require("src/ui/types")
require("src/systems/service")
require("src/battle/battle_ui_context")
require("src/story/story_ui_context")
require("src/game_context")

global type UILayoutId

global enum context_type
    "battle"
    "story"
end

global record UIContextManager

    battle_context: BattleUIContext
    story_context: StoryUIContext

    layout: UILayoutId
    
end

function UIContextManager:register_context(ctx: GameContext)
    if ctx is BattleContext then
        assert(self.battle_context == nil, "Attempt to register battle context which was already registered!")
        self.battle_context = ctx
    end
end

function UIContextManager.new(): UIContextManager
    local self: UIContextManager = setmetatable({}, { __index = UIContextManager })
    self.layout = "TACTICS"
    return self
end

function UIContextManager:enrich()
    self.layout = "TACTICS"

    -- find and enrich contexts
    if self.battle_context ~= nil then
        self.battle_context:enrich()
    end

    if self.story_context ~= nil then
        self.story_context:enrich()
    end

    -- pick layout from contexts

    if self.battle_context ~= nil then
        self.layout = self.battle_context.layout
        LOG.debug("yes battle ui context")
    elseif self.story_context ~= nil then
        self.layout = self.story_context.layout
    end
end

return UIContextManager
