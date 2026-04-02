---@brief
--- A service that manages story-wide statistics.

local stats = require("src.tactics.story.statistics.story_statistics")

local interface StatsService
    story_results: stats.StoryResults
end

local stats_service = {
    StatsService = StatsService,
}

local record StatsServiceImpl
    is StatsService
end

function stats_service.new(
): StatsService 
    local self: StatsServiceImpl = {}
    return self
end

function StatsServiceImpl:record_event(event: stats.StatisticsEvent)
    if event.type == "unit_death" then
        
    elseif event.type == "battle_complete" then

    else
        unexpected(event.type)
    end
end

return stats_service
