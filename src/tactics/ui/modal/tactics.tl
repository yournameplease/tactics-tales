---@brief
--- Defines the UI layout for a story page.

local box = require("src.tactics.ui.box")
local dialogue_node = require("src.tactics.ui.components.dialogue_node")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local point = require("src.tactics.util.point")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local menu_ui = require("src.tactics.ui.components.menu")

local modal = {}

local TILE_WIDTH = STATIC_CONFIG.TILE_WIDTH
local TILE_HEIGHT = STATIC_CONFIG.TILE_HEIGHT
local TILE_SIZE = point.of(TILE_WIDTH, TILE_HEIGHT)


local function compute_dialogue_modal_key(state: UIContextManager): integer
    return state.battle_context.dialogue_revision
end

local function compute_dialogue_modal(state: UIContextManager): box.UIElement, box.anchor.Anchor
    log.debug("Computing dialogue menu modal")
    if state.battle_context.active_dialogue == nil then
		return nil, nil
    end

    local unit = state.battle_context.active_dialogue.speaking_unit

    local x_step = unit.facing.horizontal == "left" and -4.5 or 1.5

    local x = pt.flr((unit.tile.x + x_step) * TILE_SIZE.x)
    local y = pt.flr((unit.tile.y - 0.5) * TILE_SIZE.y)

    local node = dialogue_node.single_line(
        state.battle_context.active_dialogue.dialogue,
    	{
            draw_properties = {
                wrap = "wrap",
                justify = "left",
            },
        }
    )

    local anchor: box.anchor.Anchor = {
    	target = "tactics_map",
    	ox = x,
    	oy = y,
    }

    return node, anchor
end

function modal.tactics_dialogue_menu(): box.UIElement

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
    }
	:build()

	return menu_box
end

local function compute_action_menu_modal_key(state: UIContextManager): integer
    return state.battle_context.menu_revision
end

local function compute_action_menu_modal(state: UIContextManager): box.UIElement, box.anchor.Anchor
    log.debug("Computing action menu modal")
    local menu = state.battle_context.battle_menu_manager
    local menu_step = menu.menu_step
    if menu_step == nil then
        return nil, nil
    end

    local cursor = menu_step.node
    local cursor_tile = state.battle_context.hovered_point
    
    local x: integer = 0
    local y: integer = 0

    if cursor == nil or not cursor is nested_list.NestedMenuNode then
        return nil, nil
    end
    x = pt.flr((cursor_tile.x + 1) * TILE_SIZE.x)
    y = pt.flr((cursor_tile.y - 0.5) * TILE_SIZE.y)

    local node = menu_ui.generic_menu_modal(
        -- no need to recompute as this node handles new children
        function(): integer return 0 end,
    	function (s: UIContextManager): nested_list.NestedMenuNode
    		local c = s.battle_context.battle_menu_manager.menu_step.node
    		assert(c is nested_list.NestedMenuNode)
    		return c
    	end
    )

    local anchor: box.anchor.Anchor = {
    	target = "tactics_map",
    	ox = x,
    	oy = y,
    }

    return node, anchor
end

function modal.tactics_action_menu(): box.UIElement

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
        }
	:build()

	return menu_box
end

return modal
