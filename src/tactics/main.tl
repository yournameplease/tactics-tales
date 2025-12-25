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

require("src/tactics/systems/tasks")

require("src/tactics/debug")

local event_bus = require("src/tactics/systems/event_bus")
require("src/tactics/systems/service")

require("src/tactics/character/character_manager")
require("src/tactics/animation")
require("src/tactics/ui/ui_manager")
require("src/tactics/story/story")
require("src/tactics/game/game")
require("src/tactics/ui/ui_context_manager")
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle

require("src/tactics/battle/tactics/enemy_ai")
local joypad = require("src/tactics/joypad")

require("profiler")
-- TODO: local battle_manager

local ui_context: UIContextManager = {}
local animation_manager: AnimationManager
local ui_manager: UIManager
local task_manager: TaskManager

local game: Game

local service_manager: ServiceManager


function _init()
    service_manager = ServiceManager.new()
    
    task_manager = service_manager:register(TaskManager.new())
    ui_manager = service_manager:register(UIManager.new())
    animation_manager = service_manager:register(AnimationManager.new())

    service_manager:register(event_bus.new())

    ui_context = UIContextManager.new()
    
    -- this is stupid.  delete the bundle class
    local game_services: GameServiceBundle = {
    	event_bus = service_manager.persistent_services.event_bus as event_bus.EventBus,
    	task_manager = service_manager.persistent_services.task_manager as TaskManager,
    	animation_manager = service_manager.persistent_services.animation_manager as AnimationManager,
        ui_context = ui_context
    }
    
    game = Game.new(game_services)
end

function _update()
    profile("animation_tick")
    animation_manager:tick()
    profile("animation_tick")
    LOG.trace("Getting Joypad.")
    local joy = joypad.get_joypad()
    profile("game_update")
    game:update(joy)
    profile("game_update")
    profile("update_tasks")
    task_manager:update_tasks()
    profile("update_tasks")
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
