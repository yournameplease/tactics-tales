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

require("src/game_context")
require("src/turn_manager")
require("src/menu_manager")
require("src/character")
require("src/combat/combat_calculator")
require("src/animation")
require("src/ui/ui_manager")
require("src/game_context")
require("src/battle/battle_manager")

require("src/map/map_manager")

require("src/tactics/enemy_ai")
require("src/joypad")

-- TODO: local battle_manager

local context: GameContext = {}
local animation_manager: AnimationManager
local ui_manager: UIManager
local task_manager: TaskManager

local battle_manager: BattleManager
local menu_manager: MenuManager

function _init()
    task_manager = TaskManager.new()
    ui_manager =  UIManager.new()
    animation_manager =  AnimationManager.new()

    local event_bus = EventBus.new()

    local character_manager = CharacterManager.new()
    LOG.debug(character_manager.id_counter:get_id())

    battle_manager = BattleManager.new("bandit_village", event_bus, character_manager, animation_manager, task_manager)
    local tactics_engine = battle_manager.tactics_engine
    local tile_manager = battle_manager.tile_manager
    local battle_state = battle_manager.battle_state

    menu_manager =  MenuManager.new(tactics_engine, battle_state, tile_manager, event_bus)
    local turn_manager =  TurnManager.new(event_bus, tactics_engine, battle_manager, menu_manager)

    context = GameContext.new(
        battle_manager,
        turn_manager,
        character_manager,
        menu_manager,
        event_bus
    )

    event_bus:emit("TACTICS_BEGIN_BATTLE")
end

function _update()
    LOG.trace("Getting Joypad.")
    local joy = get_joypad()
    LOG.trace("Updating menus.")
    menu_manager:update(joy)
    LOG.trace("Updating battle.")
    battle_manager:update()
    LOG.trace("Ticking animations.")
    animation_manager:tick()
    LOG.trace("Enriching context.")
    context:enrich()
    LOG.trace("Updating tasks.")
    task_manager:update_tasks()
end

function _draw()
    LOG.trace("Generating frame data.")
    animation_manager:generate_frame_data()
    LOG.trace("Drawing UI.")
    ui_manager:draw(context)
end
