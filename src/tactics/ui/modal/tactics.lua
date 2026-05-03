---@brief
--- Defines the UI layout for a campaign page.

local box = require("src.tactics.ui.box")
local dialogue_node = require("src.tactics.ui.components.dialogue_node")
local point = require("src.tactics.util.point")
local menu_ui = require("src.tactics.ui.components.menu")

local modal = {}

local TILE_WIDTH = STATIC_CONFIG.TILE_WIDTH
local TILE_HEIGHT = STATIC_CONFIG.TILE_HEIGHT
local TILE_SIZE = point.of(TILE_WIDTH, TILE_HEIGHT)

--- Return the dialogue revision as the modal cache key.
---@param state UIContextManager
---@return integer
local function compute_dialogue_modal_key(state)
    return state.battle_context.dialogue_revision
end

--- Compute the dialogue modal element and anchor for the current dialogue.
---@param state UIContextManager
---@return UIElement?, Anchor?, AvoidRect[]?
local function compute_dialogue_modal(state)
    log.debug("Computing dialogue menu modal")
    if state.battle_context.active_dialogue == nil then
        return nil, nil, nil
    end

    local unit = state.battle_context.active_dialogue.speaking_unit

    local x = math.floor((unit.tile.x + 0.5) * TILE_SIZE.x)
    local y = math.floor((unit.tile.y + 0.5) * TILE_SIZE.y)

    local node = dialogue_node.single_line(
        state.battle_context.active_dialogue.dialogue,
        {
            draw_properties = {
                wrap = "wrap",
                justify = "left",
            },
        }
    )

    ---@type Anchor
    local anchor = {
        target = "tactics_map",
        ox = x,
        oy = y,
    }

    local avoid_rects = {}
    for _, u in ipairs(state.battle_context.battle_map:get_all_units()) do
        if u ~= unit then
            table.insert(avoid_rects, {
                x = u.tile.x * TILE_WIDTH,
                y = u.tile.y * TILE_HEIGHT,
                w = TILE_WIDTH,
                h = TILE_HEIGHT,
            })
        end
    end

    return node, anchor, avoid_rects
end

--- Build and return the tactics dialogue modal box.
---@return UIElement
function modal.tactics_dialogue_menu()
    local menu_box = box.builder("tactics_dialogue_box")
        :layout{
            width = 80,
            height = 33,
            padding = box.layout.padding(2),
        }
        :style{
            decoration_padding = 1,
            solid = true,
            decoration = "border",
        }
        :modal{
            current_key = compute_dialogue_modal_key,
            compute = compute_dialogue_modal,

            priorities = {"right", "left", "up", "down"},
            anchor_margin = 16,
            screen_padding = 24,
        }
        :build()

    return menu_box
end

--- Return the action menu revision as the modal cache key.
---@param state UIContextManager
---@return integer
local function compute_action_menu_modal_key(state)
    return state.battle_context.menu_revision
end

--- Compute the action menu modal element and anchor for the current menu step.
---@param state UIContextManager
---@return UIElement?, Anchor?, AvoidRect[]?
local function compute_action_menu_modal(state)
    log.debug("Computing action menu modal")
    local menu = state.battle_context.battle_menu_manager
    local menu_step = menu.menu_step
    if menu_step == nil then
        return nil, nil, nil
    end

    local cursor = menu_step.node
    local cursor_tile = state.battle_context.hovered_point

    local x = 0
    local y = 0

    if cursor == nil or cursor.type ~= "list" then
        return nil, nil, nil
    end
    x = math.floor((cursor_tile.x + 0.5) * TILE_SIZE.x)
    y = math.floor((cursor_tile.y + 0.5) * TILE_SIZE.y)

    local node = menu_ui.generic_menu_modal(
        -- no need to recompute as this node handles new children
        function() return 0 end,
        function(s)
            local c = s.battle_context.battle_menu_manager.menu_step.node
            assert(c.type == "list")
            return c
        end
    )

    ---@type Anchor
    local anchor = {
        target = "tactics_map",
        ox = x,
        oy = y,
    }

    local acting_unit = state.battle_context.acting_unit
    local avoid_rects = {}
    for _, u in ipairs(state.battle_context.battle_map:get_all_units()) do
        if u ~= acting_unit then
            table.insert(avoid_rects, {
                x = u.tile.x * TILE_WIDTH,
                y = u.tile.y * TILE_HEIGHT,
                w = TILE_WIDTH,
                h = TILE_HEIGHT,
            })
        end
    end

    return node, anchor, avoid_rects
end

--- Build and return the tactics action menu modal box.
---@return UIElement
function modal.tactics_action_menu()
    local menu_box = box.builder("tactics_dialogue_box")
        :layout{
            width = "fit_content",
            height = "fit_content",
            padding = box.layout.padding(2),
        }
        :style{
            decoration_padding = 1,
            solid = true,
            decoration = "border",
        }
        :modal{
            current_key = compute_action_menu_modal_key,
            compute = compute_action_menu_modal,

            priorities = {"right", "left", "up", "down"},
            anchor_margin = 16,
            screen_padding = 24,
        }
        :build()

    return menu_box
end

return modal
