---@brief
--- Manages the turn and phase sequence in a battle, coordinating between
--- player, enemy, and neutral turns.

local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")

---@class Phase
---@field side Side

---@type Phase[]
local PHASE_ORDER = {
    { side = "player" },
    { side = "neutral" },
    { side = "enemy" },
}

---@class TurnManager
---@field turn integer Current turn number.
---@field chapter integer Current chapter number.
---@field phase integer Current phase index into PHASE_ORDER.
---@field package battle_map BattleMap
---@field package tactics_engine TacticsEngine
---@field package battle_objective_service BattleObjectiveService
---@field package ai_engine AIEngine
---@field package battle_menu_manager BattleMenuManager
---@field package task_manager TaskManager
---@field package event_listener EventListener
---@field package event_writer EventWriter
local TurnManager = {}
TurnManager.__index = TurnManager

local turn_manager = {
    TurnManager = TurnManager,
}

--- Return true if the battle is finished based on current objectives.
---@return boolean
function TurnManager:check_objectives()
    local battle_result = self.battle_objective_service:check_objectives(self.turn)

    if not battle_result.finished then
        log.debug("Battle still ongoing")
        return false
    else
        log.debug("Battle finished!")
        self.event_writer:emit("BATTLE_END", {
            chapter = self.chapter,
            turn_number = self.turn,
            result = battle_result.result,
        })
        return true
    end
end

--- Return the side that is currently acting.
---@return Side
function TurnManager:acting_side()
    return PHASE_ORDER[self.phase].side
end

--- Advance to the next turn, emitting turn events and refreshing units.
function TurnManager:advance_turn()
    self.event_writer:emit("TACTICS_END_TURN", {
        turn = self.turn
    })
    if not self:check_objectives() then
        self.phase = 1
        self.turn = self.turn + 1
        self.tactics_engine.turn = self.turn
        self.tactics_engine:refresh_all_units()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_writer:emit("TACTICS_BEGIN_TURN", {
            turn = self.turn
        })
    end
end

--- Advance to the next phase, running AI or showing player menu as appropriate.
function TurnManager:advance_phase()
    self.task_manager:start_routine(function()
        self.battle_menu_manager:clear_menu()
        self.event_writer:emit("TACTICS_END_PHASE", {
            turn = self.turn,
            side = self:acting_side(),
        })

        self.tactics_engine:yield_while_in_script()

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

        self.tactics_engine:yield_while_in_script()

        local side_units = self.battle_map:get_units(function(u)
            return u.side == self:acting_side()
        end)
        -- skip phases for empty sides
        if #side_units > 0 then
            if self:acting_side() ~= "player" then
                self.ai_engine:handle_one_unit_action(self:acting_side())
            else
                self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
            end
        else
            self:advance_phase()
        end
    end)
end

--- Tear down event listeners for this turn manager.
function TurnManager:teardown()
    self.event_listener:teardown()
end

--- Create a new TurnManager and wire up battle event handlers.
---@param chapter integer
---@param map BattleMap
---@param tactics_eng TacticsEngine
---@param battle_objective_srv BattleObjectiveService
---@param ai_eng AIEngine
---@param bus EventBus
---@param task_mgr TaskManager
---@param battle_menu_mgr BattleMenuManager
---@return TurnManager
function turn_manager.new(
    chapter,
    map,
    tactics_eng,
    battle_objective_srv,
    ai_eng,
    bus,
    task_mgr,
    battle_menu_mgr
)
    ---@type TurnManager
    local self = setmetatable({}, TurnManager)

    self.chapter = chapter
    self.turn = 1
    self.phase = 1

    self.battle_map = map
    self.tactics_engine = tactics_eng
    self.battle_objective_service = battle_objective_srv
    self.ai_engine = ai_eng
    self.battle_menu_manager = battle_menu_mgr
    self.task_manager = task_mgr

    self.event_listener = event_listener.new(bus)
    self.event_writer = event_writer.new(bus)

    self.event_listener:on("TACTICS_BEGIN_BATTLE", function(_)
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_writer:emit("TACTICS_BEGIN_PHASE", {
            turn = self.turn,
            side = PHASE_ORDER[1].side,
        })
        self.event_writer:emit("TACTICS_BEGIN_TURN", {
            turn = self.turn,
            side = PHASE_ORDER[1].side,
        })
    end)

    self.event_listener:on("TACTICS_UNIT_END_ACTION", function()
        self.task_manager:start_routine(function()
            self.battle_menu_manager:clear_menu()
            self.tactics_engine:yield_while_in_script()

            if not self:check_objectives() then
                local acting_side = self:acting_side()
                local to_act = function(u)
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
                    self.battle_menu_manager:clear_menu()
                    self:advance_phase()
                end
            end
        end)
    end)

    self.event_listener:on("TACTICS_FINISH_SIDE_ACTIONS", function()
        if not self:check_objectives() then
            self:advance_phase()
        end
    end)

    return self
end

return turn_manager
