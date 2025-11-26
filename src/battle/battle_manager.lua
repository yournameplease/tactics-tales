include "src/battle/battle_data.lua"

BattleManager = {}

--- Main entry point.
-- @param battle_id: Key from BATTLES
-- @return Initialized 'Tactics' state (or BattleState)
function BattleManager:create_battle(battle_id)
    local battle_definition = BATTLE_DATA[battle_id]
    assert(battle_definition ~= nil)
    
    local map_data = MapManager:load_map(MAP_DEFINITIONS[battle_definition.map_id])
    
    self:_spawn_enemies(battle_definition.enemies, map_data.metadata.enemy_spawners)
    self:_spawn_players(map_data.metadata.player_spawners)
    -- 4. local placed_party = self:_deploy_party(player_party, battle_def.deploy_zone)
    -- 5. return Tactics.new(map_data, placed_party, enemy_units, battle_def.victory)
end

--- Iterates over enemy definitions and calls CharacterManager
function BattleManager:_spawn_enemies(enemies, enemy_spawners)
    for i, enemy in ipairs(enemies) do
        local spawners = enemy_spawners[i]
        assert(spawners)
        for spawn_point in all(enemy_spawners[i]) do
            -- TODO: generate from template
            local character = CHARACTER_MANAGER.generate_character()
            BattleUnit.spawn(character, spawn_point.x, spawn_point.y, SIDE_ENEMY)
        end
    end
end

function BattleManager:_spawn_players(players, player_spawners)
    for i, player in ipairs(players) do
        local spawners = player_spawners[i]
        assert(spawners)
        for spawn_point in all(player_spawners[i]) do
            -- TODO: use existing players
            local character = CHARACTER_MANAGER.generate_character()
            BattleUnit.spawn(character, spawn_point.x, spawn_point.y, SIDE_PLAYER)
        end
    end
end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleManager:check_objectives(battle_state)
    -- returns "WIN", "LOSS", or nil (continue)
end

return BattleManager
