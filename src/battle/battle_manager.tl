require("src/debug")

require("src/types")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_state")
require("src/battle/tactics/battle_unit")
require("src/battle/tile_manager")
require("src/battle/tactics/tactics_engine")
require("src/battle/map/map_manager")
require("src/menu/menu_manager")
require("src/character/character_manager")

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record BattleManager
    battle_state: BattleState
    tile_manager: TileManager
    character_manager: CharacterManager
    tactics_engine: TacticsEngine
    event_bus: EventBus
    animation_manager: AnimationManager
    task_manager: TaskManager

    map_data: MapData
end


function BattleManager:_spawn_unit(unit: Character, spawn_point: TilePoint, side: Side)
    local battle_unit = BattleUnit.spawn(unit, spawn_point, side)
    local idle_animation = self.animation_manager:create_idle_animation()
    battle_unit.animation_data = idle_animation
    self.battle_state:spawn_unit(battle_unit, spawn_point)
end

--- Iterates over enemy definitions and calls CharacterManager
function BattleManager:_spawn_enemies(enemies: {EnemySpawnData}, enemy_spawners: {integer: {TilePoint}})
    for i, enemy in ipairs(enemies) do
        local spawners = enemy_spawners[i]
        assert(spawners)
        for _,spawn_point in ipairs(enemy_spawners[i]) do
            -- TODO: generate from template
            local character = self.character_manager:generate_character(enemy.template)
            self:_spawn_unit(character, spawn_point, SIDE_ENEMY)
        end
    end
end

function BattleManager:_spawn_players(player_spawners: { TilePoint })
    for id, spawn_point in ipairs(player_spawners) do
        -- TODO: use existing players
        local character = self.character_manager:generate_character("default")
        self:_spawn_unit(character, spawn_point, SIDE_PLAYER)
    end
end

--- Main entry point.
-- @param battle_id: Key from BATTLES
-- @return Initialized 'Tactics' state (or BattleState)
function BattleManager.new(battle_id: string, event_bus: EventBus, character_manager: CharacterManager, animation_manager: AnimationManager, task_manager: TaskManager): BattleManager
    local battle_definition = BATTLE_DATA[battle_id]
    assert(battle_definition ~= nil)

    local self: BattleManager = setmetatable({}, { __index = BattleManager })

    self.event_bus = event_bus
    self.animation_manager = animation_manager
    self.task_manager = task_manager

    self.character_manager = character_manager

    self.map_data = MapManager:load_map(battle_definition.map_id)
    
    self.battle_state = BattleState.new(self.map_data.width, self.map_data.height)

    self.tile_manager = TileManager.new(self.map_data, self.battle_state)

    self:_spawn_enemies(battle_definition.enemies, self.map_data.metadata.enemy_spawners)
    self:_spawn_players(self.map_data.metadata.player_spawners)

    self.tactics_engine = TacticsEngine.new(self.battle_state, self.tile_manager, self.event_bus, self.animation_manager, self.task_manager)

    return self
end

function BattleManager:update()
    self.tactics_engine:update()
end

global record BattleFinishState
    finished: boolean
    command: GameEvent
end

-- legacy function, doesn't support different end conditions
function BattleManager:check_for_end(): BattleFinishState
    if self.tactics_engine:is_blocked() then
        return { finished = false }
    end

    local players = self.battle_state:get_units(unit_is_player)
    local enemies = self.battle_state:get_units(unit_is_enemy)

    if (#players == 0) then
        return { finished = true, command = "BATTLE_END_VICTORY" }
    elseif (#enemies == 0) then
        return { finished = true, command = "BATTLE_END_DEFEAT" }
    else
        return { finished = false }
    end
end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleManager:check_objectives(): BattleFinishState
    -- returns "WIN", "LOSS", or nil (continue)
    return self:check_for_end()
end

return BattleManager
