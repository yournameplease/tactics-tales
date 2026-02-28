---@brief
--- Manages the UI context for the main battle screen.
--- It aggregates data from various battle systems to be displayed by the UI,
--- such as unit information, menu states, and objective text.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local point = require("src.tactics.util.point")
local Point = point.Point
local UIContext = require("src.tactics.ui.ui_context").UIContext
local TurnManager =require("src.tactics.turn_manager").TurnManager
local bm = require("src.tactics.battle.battle_map")
local TacticsEngine = require("src.tactics.battle.tactics.tactics_engine").TacticsEngine
local ActiveBattleDialogue = require("src.tactics.battle.tactics.tactics_engine").ActiveBattleDialogue
local BattleMenuManager = require("src.tactics.battle.battle_menu_manager").BattleMenuManager
local BattleObjectiveService = require("src.tactics.battle.battle_objective_service").BattleObjectiveService
local BattleUnit = require("src.tactics.battle.tactics.battle_unit").BattleUnit
local grid = require("src.tactics.menu.cursor.nested.grid")
local SerializedNestedGridState = grid.SerializedNestedGridState
local menu_context = require("src.tactics.menu.menu_context")
local BattleMainMenuContext = menu_context.BattleMainMenuContext

local record BattleUIContext
    is UIContext
    where self.type == "battle"

    battle_map: bm.BattleMap
    battle_menu_manager: BattleMenuManager
    battle_objective_service: BattleObjectiveService
    turn_manager: TurnManager
    tactics_engine: TacticsEngine
    
    hovered_point: Point
    hovered_path: {Point}
    hovered_unit: BattleUnit
	menu_tile_highlights: Userdata

    last_hovered_unit: BattleUnit
    acting_unit: BattleUnit
    destination: Point
    objective_text: {string}

    active_dialogue: ActiveBattleDialogue

    -- internal stuff
    
	dialogue_revision: integer
	menu_revision: integer
	marked_units_revision: integer
    tile_highlighted_unit: BattleUnit
    highlighted_tiles: Userdata
end

local battle_ui_context = {
    BattleUIContext = BattleUIContext
}

function battle_ui_context.new(
    map: bm.BattleMap,
    battle_menu_manager: BattleMenuManager,
    tactics_engine: TacticsEngine,
    turn_manager: TurnManager,
    battle_objective_service: BattleObjectiveService
): BattleUIContext
    local self: BattleUIContext = setmetatable({
        type = "battle"
    }, { __index = BattleUIContext })

    self.layout = "TACTICS"
    
    self.battle_map = map
    self.battle_menu_manager = battle_menu_manager
    self.tactics_engine = tactics_engine
    self.turn_manager = turn_manager
    self.battle_objective_service = battle_objective_service
    self.last_hovered_unit = nil
    self.hovered_unit = nil
    self.acting_unit = nil

    self.highlighted_tiles = pt.userdata("i16", self.battle_map.width, self.battle_map.height)
    return self
end

function BattleUIContext:enrich()
    self.layout = "TACTICS"
    local should_recalculate_highlights = false
    local should_highlight_hovered_unit = true

    local menu = self.battle_menu_manager:serialize()
    local root_node_state = menu.node and menu.node.state

    self.dialogue_revision = self.tactics_engine.dialogue_revision
    
    if self.menu_revision ~= self.battle_menu_manager.revision_count then
        if root_node_state and root_node_state is SerializedNestedGridState then
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

    if root_node_state and root_node_state is SerializedNestedGridState then
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
                and unit.side ~= acting_unit.side
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
            
            local ctx = self.battle_menu_manager.menu_ctx as {string: any}
            if ctx["unit"] ~= nil then
                self.acting_unit = ctx["unit"] as BattleUnit
            end
        end
    end

    if menu.step ~= "SELECT_DESTINATION" then
        self.hovered_path = nil
    end
    if menu.step == "SELECT_ACTION" then
        should_highlight_hovered_unit = false
    end

    local menu_ctx = self.battle_menu_manager.menu_ctx
    -- todo
    if self.turn_manager:acting_side() == "player" and menu_ctx ~= nil then
        assert(menu_ctx is BattleMainMenuContext)
        if menu_ctx.acting_unit ~= nil then
            self.acting_unit = menu_ctx.acting_unit.unit
        end

        if menu_ctx.destination ~= nil then
            self.destination = menu_ctx.destination.point
        end
    else
        self.acting_unit = nil
    end

    if root_node_state and root_node_state is SerializedNestedGridState then
        if menu.step == "SELECT_UNIT" then
            self.acting_unit = nil
        end
    end

    local unit_to_highlight: BattleUnit
    if should_highlight_hovered_unit then
        unit_to_highlight = self.hovered_unit
    end
    if unit_to_highlight ~= self.tile_highlighted_unit then
        should_recalculate_highlights = true
        self.tile_highlighted_unit = unit_to_highlight
    end

    if should_recalculate_highlights then
        log.trace("Recalculating tile highlights")
        local hover_unit_highlights: Userdata
        local menu_highlights: Userdata
        if should_highlight_hovered_unit then
            hover_unit_highlights = self.hovered_unit and self.hovered_unit.valid_tiles
        end
        menu_highlights = self.menu_tile_highlights

        local marked_unit_highlights = self.tactics_engine.marked_unit_tiles

        local tile_interaction_highlights = self.battle_map:get_tile_highlights()

        local tile_highlights = marked_unit_highlights
            | hover_unit_highlights
            | menu_highlights
            | tile_interaction_highlights
        
        for x=0,tile_highlights:width()-1 do
            for y=0,tile_highlights:height()-1 do
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
