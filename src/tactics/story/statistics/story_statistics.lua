---@brief
--- Type definitions for story statistics and chapter results.

---@class UnitDeathResult
---@field unit_id integer
---@field attacker_id integer
---@field turn_number integer
local UnitDeathResult = {}

---@class StoryChapterResult
---@field battle_id integer?
---@field turns_taken integer?
---@field was_victory boolean?
---@field units_lost UnitDeathResult[]
local StoryChapterResult = {}

---@class StoryStatistics
---@field turns_taken integer
---@field units_lost integer
local StoryStatistics = {}

--- Stores events as well as pre-computed statistics.
---@class StoryResults
---@field statistics StoryStatistics
---@field chapter_results table<integer, StoryChapterResult>
local StoryResults = {}

local stats = {
    StoryResults = StoryResults,
    StoryChapterResult = StoryChapterResult,
}

return stats
