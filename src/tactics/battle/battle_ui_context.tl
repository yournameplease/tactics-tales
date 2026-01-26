local point = require("src/tactics/util/point")
local Point = point.Point
local UIContext = require("src/tactics/ui/ui_context").UIContext
local TurnManager =require("src/tactics/turn_manager").TurnManager
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local TacticsEngine = require("src/tactics/battle/tactics/tactics_engine").TacticsEngine
local BattleMenuManager = require("src/tactics/battle/battle_menu_manager").BattleMenuManager
local BattleObjectiveService = require("src/tactics/battle/battle_objective_service").BattleObjectiveService
local BattleUnit = require("src/tactics/battle/tactics/battle_unit").BattleUnit
local BattleMenuContext = require("src/tactics/battle/battle_menu_context").BattleMenuContext
local grid_cursor = require("src/tactics/menu/cursor/grid_cursor")
local Dialogue = require("src/tactics/dialogue/dialogue").Dialogue

local MAP_WIDTH = STATIC_CONFIG.MAP_WIDTH
local MAP_HEIGHT = STATIC_CONFIG.MAP_HEIGHT

local record BattleUIContext
    is UIContext
    where self.type == "battle"

    battle_map: BattleMap
    battle_menu_manager: BattleMenuManager
    battle_objective_service: BattleObjectiveService
    turn_manager: TurnManager
    tactics_engine: TacticsEngine
    
    hovered_unit: BattleUnit
    last_hovered_unit: BattleUnit
    acting_unit: BattleUnit
    acting_unit_tiles: Userdata
    destination: Point
    objective_text: {string}

    active_dialogue: Dialogue
end

local battle_ui_context = {
    BattleUIContext = BattleUIContext
}

function battle_ui_context.new(
    map: BattleMap,
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

    self.hovered_unit = nil
    local selection = self.battle_menu_manager.menu_cursor

    if selection is grid_cursor.GridMenuCursor<BattleMenuContext> then
        if self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            local selection_point = selection.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.last_hovered_unit = unit
            end
        end

        if self.battle_menu_manager.menu_state.step == "SELECT_TARGET" then
            local selection_point = selection.point
            local unit = self.battle_map:get_at_tile(selection_point)
            self.hovered_unit = unit
            if unit then
                self.layout = "COMBAT_PREVIEW"
                self.last_hovered_unit = unit
            end
        end
    end

    if self.battle_menu_manager.menu_ctx.acting_unit ~= nil then
        self.acting_unit = self.battle_menu_manager.menu_ctx.acting_unit.unit
        if self.battle_menu_manager.menu_state.step == "SELECT_DESTINATION" then
            self.acting_unit_tiles = self.acting_unit.valid_tiles
        elseif self.battle_menu_manager.menu_state.step == "SELECT_TARGET" then
            local tile = self.acting_unit.tile
            local targeting = self.acting_unit.character:get_weapon_targeting()
            local tiles_in_range = targeting.get_selection_tiles(tile, self.battle_map)
            self.acting_unit_tiles = self.acting_unit.valid_tiles
            self.acting_unit_tiles = pt.userdata("u8", MAP_WIDTH, MAP_HEIGHT)
            for _,t in ipairs(tiles_in_range) do
                self.acting_unit_tiles:set(t.x,t.y, 0x6)
            end
        else
            self.acting_unit_tiles = nil
        end
    else
        self.acting_unit_tiles = nil
    end

    if self.battle_menu_manager.menu_ctx.destination ~= nil then
        self.destination = self.battle_menu_manager.menu_ctx.destination.point
    end

    if selection is grid_cursor.GridMenuCursor<BattleMenuContext> then
        if self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
            self.acting_unit = nil
        end
    end

    self.active_dialogue = self.tactics_engine.active_dialogue
    if self.active_dialogue ~= nil then
        self.input_actions = {
            primary = "Advance",
            secondary = "",
        }
    elseif self.battle_menu_manager.menu_state.step == "SELECT_UNIT" then
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
