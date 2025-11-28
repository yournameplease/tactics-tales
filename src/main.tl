-- tactics game
-- ynp

--[[
-- TODO: LIST
-- Next Goals
-- get helix on laptop to work on vacation
-- battle goal
- enemy/player spawn point map tiles
- multi map support

-- mid term goals
- mouse control
- learn sfx/music
- more tiles
- make ~5 maps
- title screen
- investigate mounted units possibility

--- Small but not time-critical
-- combat log
- transparency effect
- r button to cycle units


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

global CONFIG = require("src/config")
require("src/systems/tasks")

global LOG = require("src/debug")

global BUS = require("src/systems/event_bus")

global TURN_MANAGER = require("src/turn_manager")
global MENU_MANAGER = require("src/menu_manager")
global CHARACTER_MANAGER = require("src/character")
global COMBAT_CALCULATOR = require("src/combat/combat_calculator")
global ANIMATION_MANAGER = require("src/animation")
global UI_MANAGER = require("src/ui/ui_manager")
global CONTEXT_MANAGER = require("src/game_context")
global BATTLE_MANAGER = require("src/battle/battle_manager")

global MAP_MANAGER = require("src/map/map_manager")
require("src/tactics/enemy_ai")
require("src/joypad")

-- TODO: local battle_manager

local context = {}

function _init()
    global battle_manager = BATTLE_MANAGER.new("bandit_village")
    UI_MANAGER:init()
    context = CONTEXT_MANAGER.new(
            battle_manager,
            TURN_MANAGER,
            TILE_MANAGER,
            CHARACTER_MANAGER,
            MENU_MANAGER,
            BUS,
            COMBAT_CALCULATOR
    )
end

function _update()
    local joy = get_joypad()
    MENU_MANAGER.update(joy)
    battle_manager:update()
    ANIMATION_MANAGER.tick()
    context:enrich()
    update_tasks()
end

function _draw()
    UI_MANAGER:draw(context)
end
