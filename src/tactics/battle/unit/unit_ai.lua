---@brief
--- Data structures for defining the behavior of an AI-controlled unit.
--- Includes movement style and targeting preferences.

---@alias MoveAI "infinity"|"one"|"two"|"zero"

---@alias SkillPriority "prefer"|"fallback"

---@class UnitAI
---@field move MoveAI Movement range behavior for the AI unit.
---@field target_sides Side[] Which sides this unit will target.
---@field exclude_tags string[] Spawn tags to exclude when choosing targets.
---@field skill_priority? SkillPriority When set, the AI considers skills on its turn.

return {}
