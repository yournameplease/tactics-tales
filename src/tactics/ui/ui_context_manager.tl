local ui_context = require("src/tactics/ui/ui_context")
local battle_ui_context = require("src/tactics/battle/battle_ui_context")
local story_ui_context = require("src/tactics/story/story_ui_context")
local game_ui_context = require("src/tactics/game/game_ui_context")
local UILayoutId = require("src/tactics/ui/types").UILayoutId
local InputLabel = require("src/tactics/joypad").InputLabel

local record UIContextManager

    battle_context: battle_ui_context.BattleUIContext
    story_context: story_ui_context.StoryUIContext
    game_context: game_ui_context.GameUIContext

    input_actions: {InputLabel: string}

    layout: UILayoutId
    
end

local ui_context_manager = {
    UIContextManager = UIContextManager
}

function UIContextManager:register_ui_context(ctx: ui_context.UIContext)
    if ctx is battle_ui_context.BattleUIContext then
        assert(self.battle_context == nil, "Attempt to register battle context which was already registered!")
        self.battle_context = ctx
    elseif ctx is story_ui_context.StoryUIContext then
        assert(self.story_context == nil, "Attempt to register game context which was already registered!")
        self.story_context = ctx
    elseif ctx is game_ui_context.GameUIContext then
        assert(self.game_context == nil, "Attempt to register game context which was already registered!")
        self.game_context = ctx
    else
        error("Unexpexted UI Context: "..ctx.type)
    end
end

function UIContextManager:unregister_ui_context(ctx_type: ui_context.UIContextType)
    if ctx_type == 'battle' then
        assert(self.battle_context ~= nil, "Attempt to unregister battle context which was not registered!")
        self.battle_context = nil
    end
    if ctx_type == 'story' then
        assert(self.story_context ~= nil, "Attempt to unregister battle context which was not registered!")
        self.story_context = nil
    end
end

function ui_context_manager.new(): UIContextManager
    local self: UIContextManager = setmetatable({}, { __index = UIContextManager })
    self.layout = "TACTICS"
    self.input_actions = {
        primary = "Select",
        secondary = "Back",
    }

    return self
end

function UIContextManager:enrich()
    -- TODO: add a "NO_LAYOUT_FOUND"
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
    

    local primary_context: ui_context.UIContext
    if self.battle_context ~= nil then
        primary_context = self.battle_context
    elseif self.story_context ~= nil then
        primary_context = self.story_context
    elseif self.game_context ~= nil then
        primary_context = self.game_context
    end

    if primary_context ~= nil then
        self.layout = primary_context.layout
        if primary_context.input_actions ~= nil then
            self.input_actions = primary_context.input_actions
        end
    end
end

return ui_context_manager
