include "src/battle/battle_data.lua"

BattleManager = {}

--- Main entry point.
-- @param battle_id: Key from BATTLES
-- @return Initialized 'Tactics' state (or BattleState)
function BattleManager:create_battle(battle_id)
    local battle_definition = BATTLE_DATA[battle_id]
    assert(battle_definition ~= nil)
    
    local map_data = MapManager:load_map(MAP_DEFINITIONS[battle_definition.map_id])
    
    -- 3. local enemy_units = self:_spawn_enemies(battle_def.enemies)
    -- 4. local placed_party = self:_deploy_party(player_party, battle_def.deploy_zone)
    -- 5. return Tactics.new(map_data, placed_party, enemy_units, battle_def.victory)
end

--- Iterates over enemy definitions and calls CharacterManager
function BattleManager:_spawn_enemies(enemy_list) end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleManager:check_objectives(battle_state)
    -- returns "WIN", "LOSS", or nil (continue)
end

return BattleManager