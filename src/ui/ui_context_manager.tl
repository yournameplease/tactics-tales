require("src/ui/types")
require("src/systems/service")
require("src/battle/battle_context")
require("src/battle/battle_ui_context")
require("src/story/story_context")
require("src/story/story_ui_context")
require("src/game/game_ui_context")
require("src/game_context")

global type UILayoutId

global enum context_type
    "battle"
    "story"
end

global record UIContextManager

    battle_context: BattleUIContext
    story_context: StoryUIContext
    game_context: GameUIContext

    layout: UILayoutId
    
end

function UIContextManager:register_context(ctx: GameContext)
    if ctx is BattleContext then
        assert(self.battle_context == nil, "Attempt to register battle context which was already registered!")
        self.battle_context = BattleUIContext.new(ctx)
    elseif ctx is StoryContext then
        assert(self.story_context == nil, "Attempt to register game context which was already registered!")
        self.story_context = StoryUIContext.new(ctx)
    elseif ctx is BaseGameContext then
        assert(self.game_context == nil, "Attempt to register game context which was already registered!")
        self.game_context = GameUIContext.new(ctx)
    else
        error("Unexpexted UI Context: "..ctx.type)
    end
end

function UIContextManager:unregister_context(ctx_type: GameContextType)
    if ctx_type == 'battle' then
        assert(self.battle_context ~= nil, "Attempt to unregister battle context which was not registered!")
        self.battle_context = nil
    end
    if ctx_type == 'story' then
        assert(self.story_context ~= nil, "Attempt to unregister battle context which was not registered!")
        self.story_context = nil
    end
end

function UIContextManager.new(): UIContextManager
    local self: UIContextManager = setmetatable({}, { __index = UIContextManager })
    self.layout = "TACTICS"
    return self
end

function UIContextManager:enrich()
    -- TODO: add a "NO_LAYOUT_FOUND"
    -- TODO: can we simplify the ui context manager into a map of UIContexts?
    self.layout = "TITLE_SCREEN"

    -- find and enrich contexts
    if self.battle_context ~= nil then
        self.battle_context:enrich()
    end
    if self.story_context ~= nil then
        self.story_context:enrich()
    end
    if self.game_context ~= nil then
        self.game_context:enrich()
    end
    

    -- pick layout from contexts

    if self.battle_context ~= nil then
        self.layout = self.battle_context.layout
    elseif self.story_context ~= nil then
        self.layout = self.story_context.layout
    elseif self.game_context ~= nil then
        self.layout = self.game_context.layout
    end
end

return UIContextManager
