-- tactics game
-- ynp

-- static global imports
require("src/tactics/config")
require("src/tactics/debug")

local config_manager = require("src/tactics/config/config_manager")

local tasks = require("src/tactics/systems/tasks")
local event_bus = require("src/tactics/systems/event_bus")
local animation = require("src/tactics/animation")
local ui_mgr = require("src/tactics/ui/ui_manager")
local mod_ldr = require("src/tactics/mods/mod_loader")
local game = require("src/tactics/game/game")
local ui_context_manager = require("src/tactics/ui/ui_context_manager")
local input_service = require("src/tactics/joypad")
local input_context = require("src/tactics/input/input_context")
local MenuMouseSelection = require("src/tactics/menu/menu_cursor").mouse_selection.MenuMouseSelection

require("profiler")

local user_input: input_service.UserInput
local input: input_service.InputService

local ui_context: ui_context_manager.UIContextManager
local animation_manager: animation.AnimationManager
local ui_manager: ui_mgr.UIManager
local task_manager: tasks.TaskManager
local game_manager: game.Game
local bus: event_bus.EventBus

function _init()
    input = input_service.new()
    task_manager = tasks.task_manager()
    ui_manager = ui_mgr.new()
    animation_manager = animation.animation_manager()
    bus = event_bus.new()

    ui_context = ui_context_manager.new()

    local config_mgr = config_manager.new()
    local mod_loader = mod_ldr.new()
    
    game_manager = game.new(
        task_manager,
        animation_manager,
        bus,
        ui_context,
        config_mgr,
        mod_loader,
        input_service
    )
end

function _update()
    profile("animation_tick")
    animation_manager:tick()
    profile("animation_tick")
    user_input = input:get_user_input()
    local input_ctx: input_context.InputContext = nil
    if user_input.active_method == "joypad" then
        input_ctx = input_context.joypad(user_input.joypad)
    elseif user_input.active_method == "mouse" then
        local hovered: MenuMouseSelection
        if user_input.mouse ~= nil then
            hovered = ui_manager:get_mouse_selection(user_input.mouse.mx, user_input.mouse.my)
        end
        input_ctx = input_context.mouse(user_input.mouse, hovered)
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
            pt.set_window_attributes({cursor = 0})
        elseif user_input.active_method == "mouse" then
            pt.set_window_attributes({cursor = 1})
        end
    end

    profile("generate_frame_data")
    animation_manager:generate_frame_data()
    profile("generate_frame_data")
    profile("enrich_ui_context")
    ui_context:enrich()
    profile("enrich_ui_context")
    profile("draw")
    ui_manager:calculate(ui_context)
    ui_manager:draw(ui_context)
    profile("draw")
    profile.draw()
end
