local point = require("src/tactics/util/point")
local Point = point.Point
local UIContext = require("src/tactics/ui/ui_context").UIContext
local TurnManager =require("src/tactics/turn_manager").TurnManager
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local TacticsEngine = require("src/tactics/battle/tactics/tactics_engine").TacticsEngine
local BattleMenuManager = require("src/tactics/battle/battle_menu_manager").BattleMenuManager
local BattleUnit = require("src/tactics/battle/tactics/battle_unit").BattleUnit
local BattleMenuContext = require("src/tactics/battle/battle_menu_context").BattleMenuContext
local grid_cursor = require("src/tactics/menu/cursor/grid_cursor")

local MAP_WIDTH = STATIC_CONFIG.MAP_WIDTH
local MAP_HEIGHT = STATIC_CONFIG.MAP_HEIGHT

local record BattleUIContext
    is UIContext
    where self.type == "battle"

    battle_map: BattleMap
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager
    tactics_engine: TacticsEngine
    
    hovered_unit: BattleUnit
    last_hovered_unit: BattleUnit
    acting_unit: BattleUnit
    acting_unit_tiles: Userdata
    destination: Point
end

local battle_ui_context = {
    BattleUIContext = BattleUIContext
}

function battle_ui_context.new(
    map: BattleMap,
    battle_menu_mgr: BattleMenuManager,
    tactics_engine: TacticsEngine,
    turn_mgr: TurnManager
): BattleUIContext
    local self: BattleUIContext = setmetatable({
        type = "battle"
    }, { __index = BattleUIContext })

    self.layout = "TACTICS"
    
    self.battle_map = map
    self.battle_menu_manager = battle_menu_mgr
    self.tactics_engine = tactics_engine
    self.turn_manager = turn_mgr

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
            local min_range,max_range = self.acting_unit.character:get_weapon_range()
            local tiles_in_distance = self.tactics_engine:find_tiles_with_distance_from_tile(tile.x, tile.y, min_range, max_range)
            self.acting_unit_tiles = self.acting_unit.valid_tiles
            self.acting_unit_tiles = pt.userdata("u8", MAP_WIDTH, MAP_HEIGHT)
            tiles_in_distance:foreach(function(x: integer,y: integer, in_range: boolean)
                self.acting_unit_tiles:set(x,y,in_range and 0x6 or 0x0)
            end)
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
end

return battle_ui_context
