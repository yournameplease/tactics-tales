---@brief
--- Defines the interface for an active dialogue instance.

-- wrapping is separate. This only gives the raw string

---@class ActiveDialogue
---@field text string[] Lines of dialogue text (may be computed via __index for dynamic replacement).
---@field current_row integer Currently displayed row index (1-based).
---@field characters_rendered integer Non-whitespace characters rendered so far.
---@field timer? integer Current animation timer value (computed via __index metamethod).
---@field timer_limit? integer Maximum timer value before advancing (computed via __index metamethod).
---@field finished? boolean Whether all rows have been displayed.

local dialogue = {}

return dialogue
