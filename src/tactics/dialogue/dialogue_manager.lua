---@brief
--- Manages the creation and state of dialogue instances.
--- Handles text progression, speed, and variable replacement.

local lists = require("src.tactics.util.lists")

---@class DialogueProps
---@field auto_advance? boolean Advance rows automatically without waiting for input.
---@field speed? DialogueSpeed Text render speed; nil falls back to DYNAMIC_CONFIG.dialogue_speed.
---@field can_skip? boolean Allow pressing BUTTON_A to skip rendering the current row instantly.

---@class ActiveDialogue
---@field text string[]? Lines of dialogue text (may be computed via __index for dynamic replacement).
---@field current_row integer Currently displayed row index (1-based).
---@field characters_rendered integer Non-whitespace characters rendered so far.
---@field timer? integer Current animation timer value (computed via __index metamethod).
---@field timer_limit? integer Maximum timer value before advancing (computed via __index metamethod).
---@field finished? boolean Whether all rows have been displayed.
---@field package auto_advance boolean
---@field package speed? DialogueSpeed Nil falls back to DYNAMIC_CONFIG.dialogue_speed via __index.
---@field package can_skip boolean
---@field package timer_offset? integer Time offset for syncing to global timer; set immediately after construction.
local ActiveDialogue = {}

---@class DialogueManager
---@field package global_timer integer Monotonically increasing frame counter.
---@field package active_dialogues ActiveDialogue[] All currently tracked dialogue instances.
local DialogueManager = {}
DialogueManager.__index = DialogueManager

--- Negative mask: advance N characters per frame. Positive mask: advance 1 char every (mask+1) frames.
---@type table<DialogueSpeed, integer>
local SPEED_MASK = {
    very_slow =  0x07,
    slow      =  0x03,
    normal    =  0x01,
    fast      = -2,
    very_fast = -8,
    instant   = -9999,
}

--- Return the timer value for a given absolute timer and speed.
--- For positive masks this is `timer & mask` (0 at alignment points).
--- For negative masks (fast speeds) this is always 0.
---@param timer integer
---@param speed DialogueSpeed
---@return integer
local function time_at_speed(timer, speed)
    local mask = SPEED_MASK[speed]
    return mask > 0
        and timer & mask
        or 0
end

--- Replace `${key}` placeholders in every line of `text`.
--- Missing keys render as `default_value` when provided, otherwise as `[MISSING KEY: key]`.
---@param text string[]
---@param replacement_vars table<string,string>
---@param default_value string?
---@return string[]
local function replace_text(text, replacement_vars, default_value)
    return lists.map(function(t)
        local out = string.gsub(
            t,
            "${([%w_%.]+)}",
            function(key)
                local val = replacement_vars[key]
                if val == nil then
                    if default_value then
                        return default_value
                    else
                        return "[MISSING KEY: " .. key .. "]"
                    end
                end
                return val
            end)
        return out
    end)(text)
end

--- Advance all active dialogues by one frame, rendering characters and handling input.
---@param input InputContext
function DialogueManager:update(input)
    self.global_timer = self.global_timer + 1

    for _, d in ipairs(self.active_dialogues) do
        if d.current_row <= #d.text then
            local row_len = #d.text[d.current_row]
            if d.characters_rendered < row_len and d.timer == 0 then
                local mask = SPEED_MASK[d.speed]
                if mask > 0 then
                    d.characters_rendered = d.characters_rendered + 1
                else
                    d.characters_rendered = d.characters_rendered + -mask
                end
            end
            if d.characters_rendered >= row_len and d.current_row <= #d.text then
                if d.auto_advance or input.actions["BUTTON_A"].pressed then
                    log.debug("advancing dialogue")
                    d.current_row = d.current_row + 1
                    d.characters_rendered = 0
                    d.timer_offset = time_at_speed(self.global_timer, d.speed)
                    if d.current_row > #d.text then
                        d.finished = true
                    end
                end
            elseif d.can_skip and input.actions["BUTTON_A"].pressed then
                d.characters_rendered = row_len
            end
        end
    end
end

--- Create and register a new dialogue instance.
--- When `dynamic_replacement` is true, `${var}` substitutions are re-evaluated on every `text` access.
--- When `props.speed` is nil, the dialogue reads speed from `DYNAMIC_CONFIG.dialogue_speed`.
---@param text string[] Source lines, optionally containing `${key}` placeholders.
---@param props DialogueProps
---@param replacement_vars table<string,string> Map of placeholder keys to substitution values.
---@param dynamic_replacement? boolean Re-evaluate substitutions on every text read when true.
---@return ActiveDialogue
function DialogueManager:create_dialogue(text, props, replacement_vars, dynamic_replacement)
    local replaced_text = nil

    if not dynamic_replacement then
        replaced_text = replace_text(text, replacement_vars, nil)
    end

    ---@type ActiveDialogue
    local d = {
        text                = replaced_text,
        current_row         = 1,
        characters_rendered = 0,

        auto_advance = props.auto_advance,
        speed        = props.speed,
        can_skip     = props.can_skip,
    }

    local dialogue_mt = {
        __index = function(t, k)
            if k == "text" and dynamic_replacement then
                return replace_text(text, replacement_vars, "_____")
            end
            if k == "speed" then
                return DYNAMIC_CONFIG.dialogue_speed
            end
            if k == "timer" then
                return time_at_speed(self.global_timer - t.timer_offset, t.speed)
            end
            if k == "timer_limit" then
                return SPEED_MASK[t.speed] + 1
            end
        end
    }
    setmetatable(d, dialogue_mt)

    d.timer_offset = time_at_speed(self.global_timer, d.speed)
    log.debug("created text with speed: " .. d.speed)

    table.insert(self.active_dialogues, d)

    return d
end

local dialogue_manager = {}

--- Create a new DialogueManager.
---@return DialogueManager
function dialogue_manager.new()
    local self = setmetatable({
        global_timer     = 0,
        active_dialogues = {},
    }, DialogueManager)
    return self
end

return dialogue_manager
