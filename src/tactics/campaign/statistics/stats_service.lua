---@brief
--- A service that manages story-wide statistics.

local event_listener = require("src.tactics.systems.event_bus.event_listener")

--- Public interface for the stats service.
---@class StatsService
---@field story_results StoryResults
---@field package event_listener EventListener
local StatsService = {}
StatsService.__index = StatsService

--- Begin a chapter result for the given battle ID, overwriting if one already exists
---@param id integer The chapter index
---@param battle_id BattleId The battle id (from the current mod)
function StatsService:begin_chapter(
    id,
    battle_id
)
    self.story_results.chapter_results[id] = {
        units_lost = {},
        turns_taken = 0,
        battle_id = battle_id,
        result = "VICTORY"
    }
end

--- Return the chapter result for the given battle ID.
---@param id integer
---@return StoryChapterResult
function StatsService:get_chapter(id)
    assert(self.story_results.chapter_results[id])

    return self.story_results.chapter_results[id]
end

--- Record a unit death event into the appropriate chapter result.
---@param data UnitDeathPayload
function StatsService:record_death(data)
    local chapter_results = self:get_chapter(data.chapter)

    table.insert(chapter_results.units_lost, {
        unit_id = data.defender.id,
        attacker_id = data.attacker and data.attacker.id,
        turn_number = data.turn_number,
    })
end

--- Record the chapter in which a unit was recruited.
---@param unit_id UnitId
---@param chapter integer
function StatsService:record_recruitment(unit_id, chapter)
    self.story_results.chapter_recruited[unit_id] = chapter
end

--- Increment combat counts for both participants of a combat exchange.
---@param data UnitCombatPayload
function StatsService:record_combat(data)
    local combats = self.story_results.unit_combats
    combats[data.attacker_id] = (combats[data.attacker_id] or 0) + 1
    combats[data.defender_id] = (combats[data.defender_id] or 0) + 1
end

--- Record the end of a battle into the appropriate chapter result.
---@param data BattleEndPayload
function StatsService:record_battle_end(data)
    local chapter_results = self:get_chapter(data.chapter)

    chapter_results.turns_taken = data.turn_number
    chapter_results.result = data.result
end

--- Tear down event listeners.
function StatsService:teardown()
    self.event_listener:teardown()
end

local stats_service = {}

--- Create a new StatsService and register event listeners on the bus.
---@param event_bus EventBus
---@return StatsService
function stats_service.new(event_bus)
    ---@type StatsService
    local self = setmetatable({
    }, StatsService)

    self.story_results = {
        statistics = {
            turns_taken = 0,
            units_lost = 0,
        },
        chapter_results = {},
        chapter_recruited = {},
        unit_combats = {},
    }

    self.event_listener = event_listener.new(event_bus)

    self.event_listener:on("TACTICS_UNIT_DEATH", function(data)
        self:record_death(data)
    end)
    self.event_listener:on("BATTLE_END", function(data)
        self:record_battle_end(data)
    end)
    self.event_listener:on("TACTICS_BEGIN_BATTLE", function(data)
        self:begin_chapter(data.chapter, data.battle_id)
    end)
    self.event_listener:on("UNIT_COMBAT", function(data)
        self:record_combat(data)
    end)

    return self
end

return stats_service
