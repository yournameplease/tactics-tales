---@brief
--- Type definitions for story statistics and chapter results.

---@class UnitDeathResult
---@field unit_id UnitId
---@field attacker_id UnitId
---@field turn_number integer

---@class StoryChapterResult
---@field battle_id BattleId
---@field turns_taken integer
---@field result BattleEndResult
---@field units_lost UnitDeathResult[]

---@class StoryStatistics
---@field turns_taken integer
---@field units_lost integer

--- Stores events as well as pre-computed statistics.
---@class StoryResults
---@field statistics StoryStatistics
---@field chapter_results table<integer, StoryChapterResult>
---@field chapter_recruited table<UnitId, integer>
---@field unit_combats table<UnitId, integer>

return {}
