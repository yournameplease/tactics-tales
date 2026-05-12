---@brief
--- Defines data structures for skill definitions and per-battle skill state.

---@alias SkillEffectType "heal"|"damage"|"hp_cost"|"debuff"|"buff"|"spawn"|"transfer_hp"|"drain_heal"|"siphon"

---@class SkillEffect
---@field type SkillEffectType
---@field amount? integer HP restored (heal) or deducted (hp_cost).
---@field damage? integer Flat true damage applied to the target.
---@field accuracy? integer Hit chance 0–100.
---@field kind? string Subtype qualifier (debuff/buff kind).
---@field duration? integer Duration in turns.
---@field self_target? boolean When true, targets the caster instead of the skill target.

---@class SkillDefinition
---@field name string Display name shown in the Skills sub-menu.
---@field cooldown? integer Turns the skill is unavailable after use. nil = no cooldown.
---@field uses_per_battle? integer Maximum uses in a single battle. nil = unlimited.
---@field targeting Targeting Tile selection and validity functions (same interface as weapon targeting).
---@field effects SkillEffect[] Ordered list of effects applied when the skill resolves.

---@class SkillState
---@field cooldown_remaining integer Turns remaining before this skill is available again. 0 = available.
---@field uses_remaining? integer Uses left this battle. nil = unlimited.

---@class SkillStatus
---@field kind string Debuff/buff kind identifier.
---@field duration integer Turns remaining before this status expires.
---@field amount? integer Magnitude of the status effect (e.g. bonus damage, movement bonus).
