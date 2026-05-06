---@brief
--- Manages the UI context for the main battle screen.
--- It aggregates data from various battle systems to be displayed by the UI,
--- such as unit information, menu states, and objective text.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT

---@class BattleUIContext : UIContext
---@field battle_map BattleMap
---@field battle_menu_manager BattleMenuManager
---@field battle_objective_service BattleObjectiveService
---@field turn_manager TurnManager
---@field tactics_engine TacticsEngine
---@field hovered_point Point
---@field hovered_path Point[]
---@field hovered_unit BattleUnit?
---@field menu_tile_highlights userdata
---@field last_hovered_unit BattleUnit
---@field acting_unit BattleUnit
---@field destination Point
---@field objective_text string[]
---@field active_dialogue ActiveBattleDialogue
---@field dialogue_revision integer
---@field menu_revision integer
---@field marked_units_revision integer
---@field tile_highlighted_unit BattleUnit?
---@field highlighted_tiles userdata
---@field camera_x integer Camera left edge in world pixels
---@field camera_y integer Camera top edge in world pixels
---@field input_service InputService
local BattleUIContext = {}
BattleUIContext.__index = BattleUIContext

local battle_ui_context = {
    BattleUIContext = BattleUIContext
}

-- TODO: duplicated with battle_map
---Whether one side can attack the other
---@param side_1 Side
---@param side_2 Side
---@return boolean
function sides_can_fight(side_1, side_2)
    if side_1 == side_2 then
        return false
    end
    if side_1 == "player" and side_2 == "neutral" then
        return false
    end
    if side_2 == "player" and side_1 == "neutral" then
        return false
    end
    return true
end

--- Create a new BattleUIContext wiring together the battle subsystems.
---@param map BattleMap
---@param battle_menu_manager BattleMenuManager
---@param tactics_engine TacticsEngine
---@param turn_manager TurnManager
---@param battle_objective_service BattleObjectiveService
---@param input_service InputService
---@return BattleUIContext
function battle_ui_context.new(map, battle_menu_manager, tactics_engine, turn_manager, battle_objective_service,
                               input_service)
    ---@type BattleUIContext
    local self = setmetatable({ type = "battle" }, BattleUIContext)

    self.layout = "TACTICS"

    self.battle_map = map
    self.battle_menu_manager = battle_menu_manager
    self.tactics_engine = tactics_engine
    self.turn_manager = turn_manager
    self.battle_objective_service = battle_objective_service
    self.last_hovered_unit = nil
    self.hovered_unit = nil
    self.acting_unit = nil

    self.highlighted_tiles = userdata("i16", self.battle_map.width, self.battle_map.height)
    self.camera_x = 0
    self.camera_y = 0
    self.input_service = input_service
    return self
end

local VIEWPORT_W = STATIC_CONFIG.VIEWPORT_WIDTH
local VIEWPORT_H = STATIC_CONFIG.VIEWPORT_HEIGHT
local TILE_W = STATIC_CONFIG.TILE_WIDTH
local TILE_H = STATIC_CONFIG.TILE_HEIGHT

--- Move camera so target_tile stays within dead_zone tiles of viewport edges. Snaps immediately.
-- TODO: add smooth interpolation in a future pass
---@param battle_map BattleMap
---@param target_tile Point
---@param dead_zone integer Tiles from edge to keep target inside
function BattleUIContext:move_camera(battle_map, target_tile, dead_zone)
    local px = target_tile.x * TILE_W
    local py = target_tile.y * TILE_H

    local dz_px = dead_zone * TILE_W
    local dz_py = dead_zone * TILE_H

    if px < self.camera_x + dz_px then
        self.camera_x = px - dz_px
    elseif px > self.camera_x + (VIEWPORT_W - dead_zone) * TILE_W then
        self.camera_x = px - (VIEWPORT_W - dead_zone) * TILE_W
    end

    if py < self.camera_y + dz_py then
        self.camera_y = py - dz_py
    elseif py > self.camera_y + (VIEWPORT_H - dead_zone) * TILE_H then
        self.camera_y = py - (VIEWPORT_H - dead_zone) * TILE_H
    end

    self:clamp_camera(battle_map)
end

--- Clamp current camera position to valid map bounds.
---@param battle_map BattleMap
function BattleUIContext:clamp_camera(battle_map)
    local max_x = (battle_map.width - VIEWPORT_W) * TILE_W
    local max_y = (battle_map.height - VIEWPORT_H) * TILE_H
    self.camera_x = math.max(0, math.min(self.camera_x, max_x))
    self.camera_y = math.max(0, math.min(self.camera_y, max_y))
end

--- Refresh all derived UI fields from the current battle state.
function BattleUIContext:enrich()
    self.layout = "TACTICS"
    local should_recalculate_highlights = false
    local should_highlight_hovered_unit = true

    local menu = self.battle_menu_manager:serialize()
    local root_node_state = menu.node and menu.node.state
    local menu_ctx = self.battle_menu_manager.menu_ctx

    self.dialogue_revision = self.tactics_engine.dialogue_revision

    if self.menu_revision ~= self.battle_menu_manager.revision_count then
        if root_node_state and root_node_state.type == "grid" then
            ---@cast root_node_state SerializedNestedGridState
            log.debug("setting menu tile highlights", menu.step, menu.node)
            self.menu_tile_highlights = root_node_state.tile_highlights
            should_recalculate_highlights = true
        else
            log.debug("clearing menu tile highlights")
            self.menu_tile_highlights = nil
            should_recalculate_highlights = true
        end

        self.menu_revision = self.battle_menu_manager.revision_count
    end
    if self.marked_units_revision ~= self.tactics_engine.tile_reachability_cache.marked_unit_revision then
        should_recalculate_highlights = true
        self.marked_units_revision = self.tactics_engine.tile_reachability_cache.marked_unit_revision
    end

    self.hovered_unit = nil

    if root_node_state and root_node_state.type == "grid" then
        ---@cast root_node_state SerializedNestedGridState
        self.hovered_point = root_node_state.point
        if self.input_service.current_input == "joypad" then
            self:move_camera(self.battle_map, self.hovered_point, STATIC_CONFIG.CAMERA_DEAD_ZONE_PLAYER)
        end

        if menu.step == "SELECT_UNIT" then
            local selection_point = root_node_state.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.last_hovered_unit = unit
            end
        end

        if menu.step == "SELECT_DESTINATION" then
            self.hovered_path = root_node_state.path
            should_highlight_hovered_unit = false
        end

        if menu.step == "SELECT_TARGET" then
            should_highlight_hovered_unit = false
            local selection_point = root_node_state.point
            local unit = self.battle_map:get_at_tile(selection_point)
            local acting_unit = self.acting_unit
            self.hovered_unit = unit
            local targeting = self.acting_unit.character:get_weapon_targeting()
            if unit
                and sides_can_fight(unit.side, acting_unit.side)
                and targeting.is_target_valid(self.acting_unit.tile, self.hovered_unit.tile, self.battle_map) then
                self.layout = "COMBAT_PREVIEW"
                self.last_hovered_unit = unit
            end
        end

        if menu.step == "SELECT_SWAP_UNIT" then
            local selection_point = root_node_state.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.last_hovered_unit = unit
            end
            self.acting_unit = nil
        end

        if menu.step == "SELECT_SWAP_TARGET" then
            should_highlight_hovered_unit = false
            local selection_point = root_node_state.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.last_hovered_unit = unit
            end

            local ctx = self.battle_menu_manager.menu_ctx
            if ctx ~= nil then
                local unit_from_ctx = ctx["unit"]
                if unit_from_ctx ~= nil then
                    self.acting_unit = unit_from_ctx
                end
            end
        end
    end

    if menu.step ~= "SELECT_DESTINATION" then
        self.hovered_path = nil
    end
    if menu.step == "SELECT_ACTION" then
        should_highlight_hovered_unit = false
    end
    if menu.step == "CONFIRM_ATTACK" then
        if menu_ctx then
            should_highlight_hovered_unit = false
            local confirm_ctx = menu_ctx --[[@as BattleMainMenuContext]]
            local unit = confirm_ctx.target_unit and confirm_ctx.target_unit.unit
            if unit then
                self.hovered_unit = unit
            end
            self.layout = "COMBAT_PREVIEW"
            self.last_hovered_unit = unit

            local attack_points = confirm_ctx.valid_attack_points
            if attack_points and #attack_points > 0 then
                self.menu_tile_highlights = self.battle_map:get_tiles_userdata_by("u8", function(p)
                    for _, ap in ipairs(attack_points) do
                        if ap == p then return HIGHLIGHT.IS_VALID end
                    end
                    return 0
                end)
                should_recalculate_highlights = true
            end
        end
    end

    -- todo
    if self.turn_manager:acting_side() == "player" and menu_ctx ~= nil then
        ---@cast menu_ctx BattleMainMenuContext
        if menu_ctx.acting_unit ~= nil then
            self.acting_unit = menu_ctx.acting_unit.unit
        end

        if menu_ctx.destination ~= nil then
            self.destination = menu_ctx.destination.point
        end
    else
        self.acting_unit = nil
    end

    if root_node_state and root_node_state.type == "grid" then
        if menu.step == "SELECT_UNIT" then
            self.acting_unit = nil
        end
    end

    local unit_to_highlight
    if should_highlight_hovered_unit then
        unit_to_highlight = self.hovered_unit
    end
    if unit_to_highlight ~= self.tile_highlighted_unit then
        should_recalculate_highlights = true
        self.tile_highlighted_unit = unit_to_highlight
    end

    if should_recalculate_highlights then
        log.trace("Recalculating tile highlights")
        local hover_unit_highlights
        local menu_highlights
        if should_highlight_hovered_unit then
            local u = self.hovered_unit
            local already_acted = u and u:is_player() and u.has_acted
            hover_unit_highlights = (u and not already_acted) and self.tactics_engine:get_valid_tiles_for_unit(u)
        end
        menu_highlights = self.menu_tile_highlights

        local marked_unit_highlights = self.tactics_engine.tile_reachability_cache.marked_unit_tiles

        local tile_interaction_highlights = self.battle_map:get_tile_highlights()

        local tile_highlights = marked_unit_highlights
            | hover_unit_highlights
            | menu_highlights
            | tile_interaction_highlights

        for x = 0, tile_highlights:width() - 1 do
            for y = 0, tile_highlights:height() - 1 do
                local t = tile_highlights:get(x, y)

                local spr = 0
                if t & HIGHLIGHT.IS_INTERACTION_DESTINATION ~= 0 then
                    spr = 14
                elseif t & HIGHLIGHT.IS_REACHABLE ~= 0 then
                    spr = 10
                elseif t & HIGHLIGHT.IS_INTERACTION ~= 0 then
                    spr = 15
                elseif t & HIGHLIGHT.CAN_ATTACK ~= 0 then
                    spr = 11
                elseif t & HIGHLIGHT.IS_MARKED ~= 0 then
                    spr = 13
                elseif t & HIGHLIGHT.IS_VALID ~= 0 then
                    spr = 14 -- generic menu
                end
                self.highlighted_tiles:set(x, y, spr)
            end
        end
    end

    self.active_dialogue = self.tactics_engine.active_dialogue

    self.objective_text = self.battle_objective_service.objective_text
end

return battle_ui_context
