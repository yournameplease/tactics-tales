require("src/battle/battle_data.lua")

local BattleState = require("src/battle/battle_state.lua")
local BattleUnit = require("src/tactics/battle_unit.lua")
local TileManager = require("src/tiles.lua")
local Tactics = require("src/tactics.lua")

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

BattleManager = {}
BattleManager.__index = BattleManager

--- Main entry point.
-- @param battle_id: Key from BATTLES
-- @return Initialized 'Tactics' state (or BattleState)
function BattleManager.new(battle_id)
    local battle_definition = BATTLE_DATA[battle_id]
    assert(battle_definition ~= nil)

    local self = setmetatable({}, BattleManager)

    self.map_data = MapManager:load_map(battle_definition.map_id)
    
    self.battle_state = BattleState.new(self.map_data.width, self.map_data.height)

    self.tile_manager = TileManager.new(self.map_data, self.battle_state)

    MENU_MANAGER.set_menu("MENU_PLAYER_TURN")

    self:_spawn_enemies(battle_definition.enemies, self.map_data.metadata.enemy_spawners)
    self:_spawn_players(self.map_data.metadata.player_spawners)
    -- 5. return Tactics.new(map_data, placed_party, enemy_units, battle_def.victory)

    self.tactics_engine = Tactics.new(self.battle_state, self.tile_manager)

    LOG.debug(#self.battle_state.units_by_id)
    return self
end

function BattleManager:update()
    self.tactics_engine:update()
end

--- Iterates over enemy definitions and calls CharacterManager
function BattleManager:_spawn_enemies(enemies, enemy_spawners)
    for i, enemy in ipairs(enemies) do
        local spawners = enemy_spawners[i]
        assert(spawners)
        for spawn_point in all(enemy_spawners[i]) do
            -- TODO: generate from template
            local character = CHARACTER_MANAGER.generate_character()
            self:_spawn_unit(character, spawn_point.x, spawn_point.y, SIDE_ENEMY)
        end
    end
end

function BattleManager:_spawn_players(player_spawners)
    for id, spawn_point in pairs(player_spawners) do
        -- TODO: use existing players
        local character = CHARACTER_MANAGER.generate_character()
        self:_spawn_unit(character, spawn_point.x, spawn_point.y, SIDE_PLAYER)
    end
end

function BattleManager:_spawn_unit(unit, x, y, side)
    local battle_unit = BattleUnit.spawn(unit, x, y, side)
    self.battle_state:spawn_unit(battle_unit, x, y)
end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleManager:check_objectives(battle_state)
    -- returns "WIN", "LOSS", or nil (continue)
    self:check_for_end()
end

-- legacy function
function BattleManager:check_for_end()
    if self.tactics_engine:is_blocked() then
        return { finished = false }
    end

    local players = self.battle_state:get_units(unit_is_player)
    local enemies = self.battle_state:get_units(unit_is_enemy)

    if (#players == 0) then
        return { finished = true, command = "BATTLE_END_VICTORY" }
    elseif (#enemies == 0) then
        return { finished = true, command = "BATTLE_END_FAILURE" }
    else
        return { finished = false }
    end
end

return BattleManager
