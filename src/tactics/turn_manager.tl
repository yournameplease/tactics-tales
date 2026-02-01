---@brief
--- Manages the turn and phase sequence in a battle, coordinating between
--- player, enemy, and neutral turns.

local ai_engine = require("src.tactics.battle.tactics.ai_engine")
local event_bus = require("src.tactics.systems.event_bus")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local bm = require("src.tactics.battle.battle_map")
local BattleMenuManager = require("src.tactics.battle.battle_menu_manager").BattleMenuManager
local tactics_engine = require("src.tactics.battle.tactics.tactics_engine")
local battle_objective_service = require("src.tactics.battle.battle_objective_service")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local character = require("src.tactics.character.object.character")

local record Phase
    side: character.Side
end

local PHASE_ORDER: {Phase} = {
    { side = "player" },
    { side = "neutral" },
    { side = "enemy" },
} 

local interface TurnManager
    turn: integer
    phase: integer

    acting_side: function(self): character.Side

    teardown: function(self)
end

local turn_manager = {
    TurnManager = TurnManager
}

local record TurnManagerImpl
    is TurnManager

    battle_map: bm.BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    battle_objective_service: battle_objective_service.BattleObjectiveService
    ai_engine: ai_engine.AIEngine
    battle_menu_manager : BattleMenuManager

    event_listener: event_listener.EventListener
    event_writer: event_writer.EventWriter
end

---@return boolean true if battle is finished
function TurnManagerImpl:check_objectives(): boolean
    local battle_result = self.battle_objective_service:check_objectives(self.turn)

    if not battle_result.finished then
        log.debug("Battle still ongoing")
        return false
    else
        log.debug("Battle finished!")
        self.event_writer:emit(battle_result.command, {})
        return true
    end
end

function TurnManagerImpl:acting_side(): character.Side
    return PHASE_ORDER[self.phase].side
end 

function TurnManagerImpl:advance_turn()
    self.event_writer:emit("TACTICS_END_TURN", {
        turn = self.turn
    })
    if not self:check_objectives() then
        self.phase = 1
        self.turn = self.turn + 1
        self.tactics_engine:refresh_all_units()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_writer:emit("TACTICS_BEGIN_TURN", {
            turn = self.turn
        })
    end
end 

function TurnManagerImpl:advance_phase()
    self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
    self.event_writer:emit("TACTICS_END_PHASE", {
        turn = self.turn,
        side = self:acting_side(),
    })
    local next_phase = self.phase + 1
    if next_phase > #PHASE_ORDER then
        self:advance_turn()
    else
        self.phase = next_phase
    end
    self.event_writer:emit("TACTICS_BEGIN_PHASE", {
        turn = self.turn,
        side = self:acting_side(),
    })

    local side_units = self.battle_map:get_units(function(u: BattleUnit): boolean
        return u.side == self:acting_side()
    end)
    -- skip phases for empty sides
    if #side_units > 0 then
        if self:acting_side() ~= "player" then
            self.ai_engine:handle_one_unit_action(self:acting_side())
        end
    else
        self:advance_phase()
    end
end 

function turn_manager.new(
    map: bm.BattleMap,
    tactics_eng: tactics_engine.TacticsEngine,
    battle_objective_srv: battle_objective_service.BattleObjectiveService,
    ai_eng: ai_engine.AIEngine,
    bus: event_bus.EventBus,
    battle_menu_manager: BattleMenuManager
): TurnManager
    local self: TurnManagerImpl = setmetatable({
    }, { __index = TurnManagerImpl })

    self.turn = 1
    self.phase = 1

    self.battle_map = map 
    self.tactics_engine = tactics_eng
    self.battle_objective_service = battle_objective_srv
    self.ai_engine = ai_eng
    self.battle_menu_manager = battle_menu_manager

    self.event_listener = event_listener.new(bus)
    self.event_writer = event_writer.new(bus)

    self.event_listener:on("TACTICS_BEGIN_BATTLE", function(_: event_bus.EventArgs)
        self.tactics_engine:compute_unit_valid_tiles()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_writer:emit("TACTICS_BEGIN_TURN", {
            turn = self.turn,
            side = PHASE_ORDER[1].side,
        })
    end)

    self.event_listener:on("TACTICS_UNIT_END_ACTION", function()
        self.tactics_engine:compute_unit_valid_tiles()
        
        if not self:check_objectives() then
            local acting_side = self:acting_side()
            local to_act = function(u: BattleUnit): boolean
                return u.side == acting_side and not u.has_acted
            end
            local units_to_act = self.battle_map:get_units(to_act)
            if #units_to_act > 0 then
                if acting_side == "player" then
                    self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
                else
                    self.ai_engine:handle_one_unit_action(acting_side)
                end
            else
                self:advance_phase()
            end
        end
    end)

    self.event_listener:on("TACTICS_FINISH_SIDE_ACTIONS", function()
        if not self:check_objectives() then
            self:advance_phase()
        end
    end)

    self.event_listener:on("BATTLE_END_VICTORY", function()
        log.info("You win!")
    end)

    self.event_listener:on("BATTLE_END_DEFEAT", function()
        log.info("You lose!")
    end)
    
    return self
end

function TurnManagerImpl:teardown()
    self.event_listener:teardown()
end

return turn_manager
