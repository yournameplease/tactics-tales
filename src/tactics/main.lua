---@brief
--- The main entry point for the game, responsible for initializing all
--- systems and running the main game loop.

-- tactics game
-- ynp

-- static global imports
require("src.tactics.config")
require("src.tactics.debug")

local config_manager = require("src.tactics.config.config_manager")

local tasks = require("src.tactics.systems.tasks")
local event_bus = require("src.tactics.systems.event_bus")
local music_player = require("src.tactics.music.music_player")
local animation = require("src.tactics.animation")
local ui_mgr = require("src.tactics.ui.ui_manager")
local mod_ldr = require("src.tactics.mods.mod_loader")
local game = require("src.tactics.game.game")
local ui_context_manager = require("src.tactics.ui.ui_context_manager")
local input_service = require("src.tactics.joypad")
local input_context = require("src.tactics.input.input_context")

function todo(message)
	error("Function is not implemented!"..(message and " "..message or ""))
end

function unexpected(state)
	error("Received an unexpected state: "..(state and state or "nil"))
end

require("profiler")

---@type UserInput
local user_input
---@type InputService
local input

---@type UIContextManager
local ui_context
---@type AnimationManager
local animation_manager
---@type UIManager
local ui_manager
---@type TaskManager
local task_manager
---@type Game
local game_manager
---@type EventBus
local bus

function _init()
    mkdir("/appdata/tactics_tales/saves")
    
    input = input_service.new()
    task_manager = tasks.task_manager()
    ui_manager = ui_mgr.new()
    animation_manager = animation.animation_manager()
    bus = event_bus.new()
    local music = music_player.new()

    ui_context = ui_context_manager.new()

    local config_mgr = config_manager.new()
    local mod_loader = mod_ldr.new()
    
    game_manager = game.new(
        task_manager,
        animation_manager,
        bus,
        music,
        ui_context,
        config_mgr,
        mod_loader,
        input
    )

    local should_profile = DYNAMIC_CONFIG.profile
    profile.enabled(should_profile, should_profile)

    -- initial calculate, to ensure mouse has valid ui to hover
    ui_context:enrich()
    ui_manager:calculate(ui_context)
end

function _update()
    animation_manager:tick()
    user_input = input:get_user_input()
    ---@type InputContext
    local input_ctx = nil
    if user_input.active_method == "joypad" then
        input_ctx = input_context.joypad(user_input.joypad, user_input.actions)
    elseif user_input.active_method == "mouse" then
        ---@type MenuMouseSelection
        local hovered
        if user_input.mouse ~= nil then
            hovered = ui_manager:get_mouse_selection(user_input.mouse.mx, user_input.mouse.my)
        end
        input_ctx = input_context.mouse(user_input.mouse, hovered, user_input.actions)
    else
        unexpected(user_input.active_method)
    end
    profile("game_update")
    game_manager:update(input_ctx)
    profile("game_update")
    profile("update_tasks")
    task_manager:update_tasks()
    profile("update_tasks")
end

function _draw()
    if user_input.method_changed then
        if user_input.active_method == "joypad" then
            window{
                hide_cursor = "until_move"
            }
        elseif user_input.active_method == "mouse" then
        end
    end

    animation_manager:generate_frame_data()
    ui_context:enrich()
    profile("draw")
    ui_manager:calculate(ui_context)
    ui_manager:draw(ui_context)
    profile("draw")
    profile.draw()
end
