-- tactics game
-- ynp

-- MAJOR NEXT:  Finish menuing.  Send event messages on wait/attack

-- TODO LIST
-- start using an external editor (file updates)
-- unit stuff
--   enemy ai for not direct attacks
-- handle deaths


-- PROTOTYPE GOALS
-- Fully random characters, no story
-- 3-5 levels, with units carrying over between levels, plus 1-2 recruits added per level
-- Maps made with player and enemy spawn points
-- Decent UI

-- LONG TERM TODO
-- character relationships
-- class progression
-- inheritence?

include "tasks.lua"

BUS = include "event_bus.lua"
TACTICS = include "tactics.lua"
TURN_MANAGER = include "turn_manager.lua"
TILE_MANAGER = include "tiles.lua"
CHARACTER_MANAGER = include "character.lua"
COMBAT_CALCULATOR = include "combat/combat_calculator.lua"
include "tactics/enemy_ai.lua"

function _init()
    Battle:create({
        width=15, height=10
    })
end

function _draw()
    cls(22)
    Battle:draw()
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
        lp = btnp(14)
    }

    return joy
end

function _update()
    local joy = get_joypad()
    Battle:update(joy)
    update_tasks()
end