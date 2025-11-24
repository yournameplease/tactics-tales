-- tactics game
-- ynp

--[[
-- TODO: LIST
-- Next Goals
- red highlight for attack ranges
- lhs UI
-- unit details
-- combat preview ***
-- combat log
-- turn number
-- goal
- enemy/player spawn point map tiles
- multi map support
- r button to cycle units
- transparency effect

-- mid term goals
- mouse control
- learn sfx/music
- more tiles
- make ~5 maps
- title screen
- investigate mounted units possibility


-- PROTOTYPE GOALS
-- Fully random characters, no story
-- 3-5 levels, with units carrying over between levels, plus 1-2 recruits added per level
-- Maps made with player and enemy spawn points
-- Decent UI

-- LONG TERM TODO
-- character relationships
-- class progression
-- inheritence? (the human kind)
]]

include "src/systems/tasks.lua"

CONFIG = include "src/config.lua"
BUS = include "src/systems/event_bus.lua"
TACTICS = include "src/tactics.lua"
TURN_MANAGER = include "src/turn_manager.lua"
MENU_MANAGER = include "src/menu_manager.lua"
TILE_MANAGER = include "src/tiles.lua"
CHARACTER_MANAGER = include "src/character.lua"
COMBAT_CALCULATOR = include "src/combat/combat_calculator.lua"
ANIMATION_MANAGER = include "src/animation.lua"
UI_MANAGER = include "src/ui/ui_manager.lua"
CONTEXT_MANAGER = include "src/game_context.lua"
DEBUG = include "src/debug.lua"
include "src/tactics/enemy_ai.lua"

local context = {}

function _init()
    Battle:create({
        width=15, height=10
    })
    UI_MANAGER:init()
    context = CONTEXT_MANAGER.new(
            TACTICS,
            TURN_MANAGER,
            TILE_MANAGER,
            CHARACTER_MANAGER,
            MENU_MANAGER
    )
end

function get_joypad()
    local joy = {
        dx = (btn(1) or 0) - (btn(0) or 0),
        dxp = (btnp(1) and 1 or 0) - (btnp(0) and 1 or 0),
        dy = (btn(3) or 0) - (btn(2) or 0),
        dyp = (btnp(3) and 1 or 0) - (btnp(2) and 1 or 0),
        a = btn(4),
        ap = btnp(4),
        b = btn(5),
        bp = btnp(5),
        lp = btnp(14) -- debug button.  Set to next turn
    }

    return joy
end

function _update()
    local joy = get_joypad()
    MENU_MANAGER.update(joy)
    Battle:update(joy)
    ANIMATION_MANAGER.tick()
    update_tasks()
end

function _draw()
    UI_MANAGER:draw(context)
end