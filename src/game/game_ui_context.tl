require("src/ui/types")
require("src/battle/tactics/tactics_engine")
require("src/turn_manager")
require("src/game/base_game_context")

global type UILayoutId

global record GameUIContext
    ctx: BaseGameContext

    layout: UILayoutId
end

function GameUIContext.new(ctx: BaseGameContext): GameUIContext
    local context: GameUIContext = setmetatable({
        ctx = ctx
    }, { __index = GameUIContext })
    return context
end

function GameUIContext:enrich()
    self.layout = "TITLE_SCREEN"

end

return GameUIContext

