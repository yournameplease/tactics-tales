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
---@return BattleUIContext
function battle_ui_context.new(map, battle_menu_manager, tactics_engine, turn_manager, battle_objective_service)
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
    return self
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
            local root_node_state = root_node_state --[[@as SerializedNestedGridState]]
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
    if self.marked_units_revision ~= self.tactics_engine.marked_unit_revision then
        should_recalculate_highlights = true
        self.marked_units_revision = self.tactics_engine.marked_unit_revision
    end

    self.hovered_unit = nil

    if root_node_state and root_node_state.type == "grid" then
        local root_node_state = root_node_state --[[@as SerializedNestedGridState]]
        self.hovered_point = root_node_state.point

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
        end
    end

    -- todo
    if self.turn_manager:acting_side() == "player" and menu_ctx ~= nil then
        local menu_ctx = menu_ctx --[[@as BattleMainMenuContext]]
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
            hover_unit_highlights = self.hovered_unit and self.tactics_engine:get_valid_tiles_for_unit(self.hovered_unit)
        end
        menu_highlights = self.menu_tile_highlights

        local marked_unit_highlights = self.tactics_engine.marked_unit_tiles

        local tile_interaction_highlights = self.battle_map:get_tile_highlights()

        local tile_highlights = marked_unit_highlights
            | hover_unit_highlights
            | menu_highlights
            | tile_interaction_highlights

        for x = 0, tile_highlights:width() - 1 do
            for y = 0, tile_highlights:height() - 1 do
                local t = tile_highlights:get(x, y)

                local spr = 0
                if t & HIGHLIGHT.IS_REACHABLE ~= 0 then
                    spr = 10
                elseif t & HIGHLIGHT.IS_INTERACTION ~= 0 then
                    spr = 15
                elseif t & HIGHLIGHT.CAN_ATTACK ~= 0 then
                    spr = 11
                elseif t & HIGHLIGHT.IS_MARKED ~= 0 then
                    spr = 13
                elseif t & HIGHLIGHT.IS_VALID ~= 0 then
                    spr = 10 -- generic menu
                end
                self.highlighted_tiles:set(x, y, spr)
            end
        end
    end

    self.active_dialogue = self.tactics_engine.active_dialogue

    -- todo: cache
    self.objective_text = self.battle_objective_service:get_objective_text(self.turn_manager.turn)
end

return battle_ui_context
