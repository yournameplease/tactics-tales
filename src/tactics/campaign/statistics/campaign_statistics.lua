---@brief
--- Type definitions for campaign statistics and chapter results.

---@class UnitDeathResult
---@field unit_id UnitId
---@field attacker_id UnitId
---@field turn_number integer

---@class GameResultsChapterDisplay
---@field chapter_number integer
---@field battle_id BattleId
---@field result BattleEndResult
---@field turns_taken integer
---@field units_lost_names string[]

---@class GameResultsUnitDisplay
---@field drawable DrawableCharacter
---@field name string
---@field chapter_recruited integer?
---@field combats integer
---@field kills integer

---@class CampaignChapterResult
---@field battle_id BattleId
---@field turns_taken integer
---@field result BattleEndResult
---@field units_lost UnitDeathResult[]
---@field deaths_by_side table<Side, integer>

---@class CampaignStatistics
---@field turns_taken integer
---@field units_lost integer

--- Stores events as well as pre-computed statistics.
---@class CampaignResults
---@field statistics CampaignStatistics
---@field chapter_results table<integer, CampaignChapterResult>
---@field chapter_recruited table<UnitId, integer>
---@field unit_combats table<UnitId, integer>

return {}
