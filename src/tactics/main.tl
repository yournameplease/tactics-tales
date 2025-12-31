-- tactics game
-- ynp

--[[
-- TODO: LIST
-- Next Goals
-- battle goal

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

local tasks = require("src/tactics/systems/tasks")

require("src/tactics/debug")

local event_bus = require("src/tactics/systems/event_bus")
require("src/tactics/character/character_manager")
require("src/tactics/animation")
require("src/tactics/ui/ui_manager")
local game = require("src/tactics/game/game")
require("src/tactics/ui/ui_context_manager")
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle
local joypad = require("src/tactics/joypad")

require("profiler")

local ui_context: UIContextManager = {}
local animation_manager: AnimationManager
local ui_manager: UIManager
local task_manager: tasks.TaskManager

local game_manager: game.Game

function _init()
    task_manager = tasks.task_manager()
    ui_manager = UIManager.new()
    animation_manager = AnimationManager.new()
    event_bus = event_bus.new()

    ui_context = UIContextManager.new()
    
    -- this is stupid.  delete the bundle class
    local game_services: GameServiceBundle = {
    	event_bus = event_bus,
    	task_manager = task_manager,
    	animation_manager = animation_manager,
        ui_context = ui_context,
    }
    
    game_manager = game.new(game_services)
end

function _update()
    profile("animation_tick")
    animation_manager:tick()
    profile("animation_tick")
    LOG.trace("Getting Joypad.")
    local joy = joypad.get_joypad()
    profile("game_update")
    game_manager:update(joy)
    profile("game_update")
    profile("update_tasks")
    task_manager:update_tasks()
    profile("update_tasks")

    -- LOG.debug("MEM",  pt.stat(0))
end

function _draw()
    profile("generate_frame_data")
    animation_manager:generate_frame_data()
    profile("generate_frame_data")
    profile("enrich_ui_context")
    ui_context:enrich()
    profile("enrich_ui_context")
    profile("draw")
    ui_manager:draw(ui_context)
    profile("draw")
    profile.draw()
end
