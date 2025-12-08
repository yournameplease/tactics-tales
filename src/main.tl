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

require("src/systems/tasks")

require("src/debug")

require("src/systems/event_bus")
require("src/systems/service")

require("src/game_context")
require("src/character/character_manager")
require("src/battle/combat/combat_calculator")
require("src/animation")
require("src/ui/ui_manager")
require("src/game_context")
require("src/battle/battle_manager")


require("src/battle/tactics/enemy_ai")
require("src/joypad")

-- TODO: local battle_manager

local context: GameContext = {}
local animation_manager: AnimationManager
local ui_manager: UIManager
local task_manager: TaskManager

local battle_manager: BattleManager
local menu_manager: MenuManager

local service_manager: ServiceManager


function _init()
    service_manager = ServiceManager.new()
    service_manager:register(service_manager)
    
    task_manager = service_manager:register(TaskManager.new())
    ui_manager = service_manager:register(UIManager.new())
    animation_manager = service_manager:register(AnimationManager.new())

    service_manager:register(EventBus.new())

    CharacterManager.new()

    battle_manager = service_manager:register(BattleManager.new("bandit_village"))


    context = service_manager:register(GameContext.new())

end

function _update()
    LOG.trace("Getting Joypad.")
    local joy = get_joypad()
    menu_manager:update(joy)
    battle_manager:update()
    animation_manager:tick()
    context:enrich()
    task_manager:update_tasks()
end

function _draw()
    LOG.trace("Generating frame data.")
    animation_manager:generate_frame_data()
    ui_manager:draw(context)
end
