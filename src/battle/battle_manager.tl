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
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record BattleManager
    is TransientGameService
    where self.id == 'battle_manager'

    battle_id: string

    battle_state: BattleState
    tile_manager: TileManager
    character_manager: CharacterManager
    tactics_engine: TacticsEngine
    event_bus: EventBus
    animation_manager: AnimationManager
    task_manager: TaskManager

    menu_manager: MenuManager
    enemy_ai_engine: EnemyAIEngine
    turn_manager: TurnManager

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


function BattleManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
    local battle_definition = BATTLE_DATA[self.battle_id]

    self.event_bus = services.event_bus as EventBus
    self.animation_manager = services.animation_manager as AnimationManager
    self.task_manager = services.task_manager as TaskManager
    self.character_manager = services.character_manager as CharacterManager

    self.map_data = MapManager:load_map(battle_definition.map_id)
    
    self.battle_state = service_manager:register_transient(BattleState.new(self.map_data.width, self.map_data.height))

    self.tile_manager = service_manager:register_transient(TileManager.new(self.map_data))

    self:_spawn_enemies(battle_definition.enemies, self.map_data.metadata.enemy_spawners)
    self:_spawn_players(self.map_data.metadata.player_spawners)

    self.tactics_engine = service_manager:register_transient(TacticsEngine.new())

    self.menu_manager = service_manager:register_transient(MenuManager.new())
    self.enemy_ai_engine = service_manager:register_transient(EnemyAIEngine.new())
    self.turn_manager = service_manager:register_transient(TurnManager.new())

    self.event_bus:emit("TACTICS_BEGIN_BATTLE")
end

function BattleManager.new(battle_id: string): BattleManager 
    assert(BATTLE_DATA[battle_id] ~= nil)

    local self: BattleManager = setmetatable({
        id = 'battle_manager',
        dependencies = {
            "event_bus",
            "animation_manager",
            "task_manager",
            "character_manager",
        }
    }, { __index = BattleManager })
    self.battle_id = battle_id

    return self
end

function BattleManager:update()
    self.tactics_engine:update()
end

return BattleManager
