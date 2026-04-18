---@brief
--- Type definitions for story statistics and chapter results.

---@class UnitDeathResult
---@field unit_id UnitId
---@field attacker_id UnitId
---@field turn_number integer
local UnitDeathResult = {}

---@class StoryChapterResult
---@field battle_id string
---@field turns_taken integer
---@field result BattleEndResult
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

return {}
