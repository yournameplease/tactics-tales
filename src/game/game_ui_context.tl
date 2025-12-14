require("src/ui/types")
require("src/battle/tactics/tactics_engine")
require("src/turn_manager")
require("src/game/base_game_context")
require("src/game/game_menu_manager")

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

    if self.ctx.menu_manager.menu_state.menu_id == "MENU_MAIN_MENU" then
        if self.ctx.menu_manager.menu_state.step == "MAIN_MENU" then
            self.layout = "MAIN_MENU_PAGE"
        end
    end
end

return GameUIContext

