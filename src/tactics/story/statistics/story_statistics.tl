
local record UnitDeathResult
	unit_id: integer
	attacker_id: integer
	turn_number: integer
end

local record StoryChapterResult
	battle_id: integer
	turns_taken: integer
	was_victory: boolean
	units_lost: { UnitDeathResult }
end

local record StoryStatistics
	turns_taken: integer
	units_lost: integer
end

---@desc stores events as well as pre-computed statistict
local record StoryResults
	statistics: StoryStatistics
	chapter_results: {integer: StoryChapterResult}
end

local stats = {
	StoryResults = StoryResults,
	StoryChapterResult = StoryChapterResult,
}


return stats
