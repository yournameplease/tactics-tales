---@brief
--- Manages the UI context for the main battle screen.
--- It aggregates data from various battle systems to be displayed by the UI,
--- such as unit information, menu states, and objective text.

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
local array_2d = require("src.tactics.util.array_2d")

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
	tile_highlights: array_2d.Array2D<grid.MenuTileHighlight>

    last_hovered_unit: BattleUnit
    acting_unit: BattleUnit
    destination: Point
    objective_text: {string}

    active_dialogue: ActiveBattleDialogue
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
    return self
end

function BattleUIContext:enrich()
    self.layout = "TACTICS"

    local menu = self.battle_menu_manager:serialize()
    local root_node_state = menu.node.state

    self.hovered_unit = nil

    if root_node_state is SerializedNestedGridState then
        self.hovered_point = root_node_state.point
        self.hovered_path = root_node_state.path
        self.tile_highlights = root_node_state.tile_highlights

        if menu.step == "SELECT_UNIT" then
            local selection_point = root_node_state.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.last_hovered_unit = unit
            end
        end

        if menu.step == "SELECT_TARGET" then
            local selection_point = root_node_state.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
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

    local menu_ctx = self.battle_menu_manager.menu_ctx
    -- todo
    if self.turn_manager:acting_side() == "player" then
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

    if root_node_state is SerializedNestedGridState then
        if menu.step == "SELECT_UNIT" then
            self.acting_unit = nil
        end
    end

    -- TODO: these names should live in the menu manager definition
    self.active_dialogue = self.tactics_engine.active_dialogue
    if self.active_dialogue ~= nil then
        self.input_actions = {
            primary = "Advance",
            secondary = "",
        }
    elseif menu.step == "SELECT_UNIT" then
        self.input_actions = {
            primary = "Select",
            secondary = "Mark unit range",
        }
    else
        self.input_actions = {
            primary = "Select",
            secondary = "Back",
        }
    end
    -- log.debug("dialogue", self.active_dialogue)

    -- todo: cache
    self.objective_text = self.battle_objective_service:get_objective_text(self.turn_manager.turn)
end

return battle_ui_context
