---@brief
--- Defines data structures for skill definitions and per-battle skill state.

---@alias SkillEffectType "heal"|"damage"

---@class SkillDefinition
---@field name string Display name shown in the Skills sub-menu.
---@field effect_type SkillEffectType Determines how the skill resolves.
---@field heal_amount? integer HP restored to the target. Required when effect_type is "heal".
---@field damage? integer Flat true damage applied to the target. Required when effect_type is "damage".
---@field accuracy? integer Hit chance 0–100. Required when effect_type is "damage".
---@field hp_cost? integer HP deducted from the caster on use. Caster may die; effect still fires.
---@field cooldown? integer Turns the skill is unavailable after use (decrements at start of caster's next turn). nil = no cooldown.
---@field uses_per_battle? integer Maximum uses in a single battle. nil = unlimited.
---@field targeting Targeting Tile selection and validity functions (same interface as weapon targeting).

---@class SkillState
---@field cooldown_remaining integer Turns remaining before this skill is available again. 0 = available.
---@field uses_remaining? integer Uses left this battle. nil = unlimited.
