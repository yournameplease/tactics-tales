require("src/debug")

require("src/types")
require("src/joypad")
require("src/systems/event_bus")
require("src/systems/tasks")

require("src/data/battles")

require("src/battle/battle_ui_context")
require("src/battle/battle_map")
require("src/battle/tactics/battle_unit")
require("src/battle/pathfinding")
require("src/battle/tactics/tactics_engine")
require("src/battle/map/map_generator")
require("src/menu/menu_manager")
require("src/systems/service")
require("src/character/character_manager")
require("src/turn_manager")
require("src/battle/tactics/enemy_ai")
require("src/battle/battle_objective_service")
require("src/battle/battle_context")


local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record BattleManager
    is TransientGameService
    where self.id == 'battle_manager'

    battle_context: BattleContext
    
end


function BattleManager:_spawn_unit(unit: Character, spawn_point: TilePoint, side: Side)
    local battle_unit = BattleUnit.spawn(unit, spawn_point, side)
    local idle_animation = self.battle_context.services.animation_manager:create_idle_animation()
    battle_unit.animation_data = idle_animation
    self.battle_context.battle_map:spawn_unit(battle_unit, spawn_point)
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
    for _id, spawn_point in ipairs(player_spawners) do
        -- TODO: use existing players
        local character = self.character_manager:generate_character("default")
        self:_spawn_unit(character, spawn_point, SIDE_PLAYER)
    end
end


function BattleManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
    local battle_definition = BATTLE_DATA[self.battle_context.battle_id]

    self.event_bus = services.event_bus as EventBus
    self.animation_manager = services.animation_manager as AnimationManager
    self.task_manager = services.task_manager as TaskManager
    self.character_manager = services.character_manager as CharacterManager

    self.battle_context.battle_map = MapGenerator:load_map(battle_definition.map_id)
    
    self.battle_context.battle_map = BattleMap.new(self.battle_context.battle_map.width, self.battle_context.battle_map.height)

    self:_spawn_enemies(battle_definition.enemies, self.battle_context.battle_map.metadata.enemy_spawners)
    self:_spawn_players(self.battle_context.battle_map.metadata.player_spawners)

    self.battle_context.tactics_engine = TacticsEngine.new()

    self.battle_context.battle_objective_service = BattleObjectiveService.new()

    self.battle_context.battle_menu_manager = BattleMenuManager.new()
    self.battle_context.enemy_ai_engine = EnemyAIEngine.new()
    self.battle_context.turn_manager = TurnManager.new()
    self.event_bus:emit("TACTICS_BEGIN_BATTLE")
end

function BattleManager.new(battle_id: string, game_services: GameServiceBundle): BattleManager 
    assert(BATTLE_DATA[battle_id] ~= nil)

    local self: BattleManager = setmetatable({}, { __index = BattleManager })
    self.battle_context = BattleContext.new(game_services)
    self.battle_context.battle_id = battle_id

    local battle_definition = BATTLE_DATA[self.battle_context.battle_id]

    self.battle_context.battle_map = MapGenerator:load_map(battle_definition.map_id)
    
    self.battle_context.battle_map = BattleMap.new(self.battle_context.battle_map.width, self.battle_context.battle_map.height)

    self:_spawn_enemies(battle_definition.enemies, self.battle_context.battle_map.metadata.enemy_spawners)
    self:_spawn_players(self.battle_context.battle_map.metadata.player_spawners)

    self.battle_context.tactics_engine = TacticsEngine.new(self.battle_context)

    self.battle_context.battle_objective_service = BattleObjectiveService.new(self.battle_context)

    self.battle_context.battle_menu_manager = BattleMenuManager.new(self.battle_context)
    self.battle_context.enemy_ai_engine = EnemyAIEngine.new(self.battle_context)
    self.battle_context.turn_manager = TurnManager.new(self.battle_context)

    self.battle_context.services.event_bus:emit("TACTICS_BEGIN_BATTLE")
    return self
end

function BattleManager:update(joy: Joypad)
    self.battle_context.battle_menu_manager:update(joy)
    self.battle_context.tactics_engine:update()
end

return BattleManager
