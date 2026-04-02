
local enum StatisticsEventType
	"unit_death"
	"battle_complete"
end

local interface StatisticsEvent
	type: StatisticsEventType
end

local record UnitDeath
	is StatisticsEvent
	where self.type == "unit_death"
	unit_id: integer 
end

local record StoryChapterResult
	battle_id: integer
	turns_taken: integer
	was_victory: boolean
end

local record StoryStatistics
	turns_taken: integer
	units_lost: integer
end

---@desc stores events as well as pre-computed statistict
local record StoryResults
	statistics: StoryStatistics
	chapter_results: {StoryChapterResult}
end

local stats = {
	StoryResults = StoryResults,
	StatisticsEvent = StatisticsEvent,
}


return stats
