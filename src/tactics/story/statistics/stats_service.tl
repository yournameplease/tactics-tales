---@brief
--- A service that manages story-wide statistics.

local event_listener = require("src.tactics.systems.event_bus.event_listener")
local EventBus = require("src.tactics.systems.event_bus").EventBus
local stats = require("src.tactics.story.statistics.story_statistics")
local payloads = require("src.tactics.battle.tactics.types").payloads

local interface StatsService
    story_results: stats.StoryResults

	teardown: function(self)
end

local stats_service = {
    StatsService = StatsService,
}

local record StatsServiceImpl
    is StatsService
    event_listener: event_listener.EventListener
end

function StatsServiceImpl:get_chapter(id: integer): stats.StoryChapterResult
    if self.story_results.chapter_results[id] == nil then
        self.story_results.chapter_results[id] = {
            units_lost = {}
        }
    end

    return self.story_results.chapter_results[id]
end

function StatsServiceImpl:record_death(data: payloads.UnitDeathPayload)
    local chapter_results = self:get_chapter(data.chapter)
      
    pt.add(chapter_results.units_lost, {
        unit_id = data.defender.id,  
        attacker_id = data.attacker.id,  
        turn_number = data.turn_number,
    })
end

function stats_service.new(
    event_bus: EventBus
): StatsService 
    local self: StatsServiceImpl = {}

    self.event_listener = event_listener.new(event_bus)

    self.event_listener:on("TACTICS_UNIT_DEATH", function(data: payloads.UnitDeathPayload)
        self:record_death(data)
    end)

    return self
end

function StatsServiceImpl:teardown()
    self.event_listener:teardown()
end

return stats_service
