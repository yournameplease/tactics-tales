require("src/tactics/debug")

require("src/tactics/types")
local Joypad = require("src/tactics/joypad").Joypad
require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")

require("src/tactics/data/battles")

require("src/tactics/battle/battle_map")
require("src/tactics/battle/tactics/battle_unit")
require("src/tactics/battle/pathfinding")
require("src/tactics/battle/tactics/tactics_engine")
local map_generator = require("src/tactics/battle/map/map_generator")
require("src/tactics/menu/menu_manager")
require("src/tactics/ui/ui_context_manager")
local battle_ui_context = require("src/tactics/battle/battle_ui_context")
local character_manager = require("src/tactics/character/character_manager")
require("src/tactics/turn_manager")
require("src/tactics/battle/tactics/enemy_ai")
require("src/tactics/battle/battle_objective_service")
local battle_menu_context = require("src/tactics/battle/battle_context")
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record BattleManager

    battle_id: string
	
    battle_map: BattleMap

    tactics_engine: TacticsEngine
    battle_objective_service: BattleObjectiveService
    enemy_ai_engine: EnemyAIEngine
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager

    character_manager: CharacterManager

    services: GameServiceBundle
end


function BattleManager:_spawn_unit(unit: Character, spawn_point: TilePoint, side: Side)
    local battle_unit = BattleUnit.spawn(unit, spawn_point, side)
    local idle_animation = self.services.animation_manager:create_idle_animation()
    battle_unit.animation_data = idle_animation
    self.battle_map:spawn_unit(battle_unit, spawn_point)
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

function BattleManager:_spawn_players(new_players: {PlayerSpawnData}, player_spawners: { TilePoint })
    local char_man = self.character_manager
    local player_roster = char_man:get_player_roster()
    local roster_count = 1
    for i, spawn_point in ipairs(player_spawners) do
        -- TODO: use existing players
        local character: Character
        if new_players[i] ~= nil then
            local spawn_data = new_players[i]
            character = char_man:generate_character(spawn_data.template)
            char_man:persist_player(character)
        else
            if player_roster[roster_count] ~= nil then
                character = player_roster[roster_count]
                roster_count = roster_count + 1
            end
        end
        self:_spawn_unit(character, spawn_point, SIDE_PLAYER)
    end
end


function BattleManager.new(battle_id: string, character_manager: CharacterManager, services: GameServiceBundle): BattleManager 
    assert(BATTLE_DATA[battle_id] ~= nil)

    local self: BattleManager = setmetatable({}, { __index = BattleManager })
    self.services = services

    self.battle_id = battle_id
    self.character_manager = character_manager

    local battle_definition = BATTLE_DATA[self.battle_id]

    self.battle_map = map_generator.load_map(battle_definition.map_id)

    self:_spawn_enemies(battle_definition.enemies, self.battle_map.metadata.enemy_spawners)
    self:_spawn_players(battle_definition.players, self.battle_map.metadata.player_spawners)

    self.tactics_engine = TacticsEngine.new(
        self.battle_map,
        self.services.task_manager,
        self.services.animation_manager,
        self.services.event_bus
    )

    self.battle_objective_service = BattleObjectiveService.new(
        self.battle_map,
        self.tactics_engine
    )

    self.enemy_ai_engine = EnemyAIEngine.new(
        self.battle_map,
        self.tactics_engine,
        self.services.event_bus,
        self.services.task_manager
    )
    
    local battle_menu_context = battle_menu_context.new(
        self.battle_map,
        self.tactics_engine
    )
    self.battle_menu_manager = BattleMenuManager.new(
        battle_menu_context,
        self.services.event_bus
    )
    
    self.turn_manager = TurnManager.new(
        self.battle_map,
        self.tactics_engine,
        self.battle_objective_service,
        self.enemy_ai_engine,
        self.services.event_bus,
        self.battle_menu_manager
    )

    local battle_ui_context = battle_ui_context.new(
        self.battle_map,
        self.battle_menu_manager,
        self.turn_manager
    )
    self.services.ui_context:register_ui_context(battle_ui_context)

    self.services.event_bus:emit("TACTICS_BEGIN_BATTLE")
    return self
end

function BattleManager:teardown()
    self.services.ui_context:unregister_ui_context('battle')
    self.turn_manager:teardown()
end

function BattleManager:update(joy: Joypad)
    self.battle_menu_manager:update(joy)
    self.tactics_engine:update()
end

return BattleManager
