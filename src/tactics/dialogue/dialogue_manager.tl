---@brief
--- Manages the creation and state of dialogue instances.
--- Handles text progression, speed, and variable replacement.

local lists = require("src.tactics.util.lists")
local dialogue = require("src.tactics.dialogue.dialogue")
local Dialogue = dialogue.Dialogue

local InputContext = require("src.tactics.input.input_context").InputContext

local record DialogueProps
	auto_advance: boolean
	speed: DialogueSpeed
	can_skip: boolean
end

local interface DialogueManager
	update: function(self, input: InputContext)
	create_dialogue: function(
		self,
		text: {string},
		props: DialogueProps,
		replacement_vars: {string: string}
	): Dialogue
end

local record DialogueImpl
	is Dialogue
	texts: {string}
	i: integer
	
	auto_advance: boolean
	speed: DialogueSpeed
	can_skip: boolean
	timer_offset: integer
end

local dialogue_manager = {
	Dialogue = Dialogue,
	DialogueImpl = DialogueImpl,
	DialogueManager = DialogueManager
}

local record DialogueManagerImpl
	is DialogueManager

	global_timer: integer
	active_dialogues: { DialogueImpl }
end

function dialogue_manager.new(): DialogueManager
	local self: DialogueManagerImpl = setmetatable({
		global_timer = 0,
		active_dialogues = {},
	}, {
		__index = DialogueManagerImpl 
	}) 

	return self
end

-- negative N: every frame, for N chars
local SPEED_MASK <total>: {DialogueSpeed: integer} = {
	very_slow = 0x07,
	slow = 0x03,
	normal = 0x01,
	fast = -2,
	very_fast = -8,
	instant = -9999,
}

local function time_at_speed(timer: integer, speed: DialogueSpeed): integer
	local mask = SPEED_MASK[speed]
	return mask > 0
		and timer & mask
		or 0
end

function DialogueManagerImpl:update(input: InputContext)
	self.global_timer = self.global_timer + 1

	for _,d in ipairs(self.active_dialogues) do
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
				if d.auto_advance
					or input.actions["ADVANCE"].pressed
				then
					log.debug("advancing dialogue")
					d.current_row = d.current_row + 1
					d.characters_rendered = 0
					d.timer_offset = time_at_speed(self.global_timer, d.speed)
					if d.current_row > #d.text then
						d.finished = true
					end
				end
		    end
		end
	end
end

function DialogueManagerImpl:create_dialogue(
	text: {string},
	props: DialogueProps,
	replacement_vars: {string: string}
): Dialogue
	local replaced_text = lists.map(function(t: string): string
		local out = string.gsub(
			t,
			"${([%w_%.]+)}",
			function(key: string): string
				local val = replacement_vars[key]
				if val == nil then
					return "[MISSING KEY: "..key.."]"
				end
				return val
			end)
		return out
		end
	)(text)
	
	local d: DialogueImpl = {
		text = replaced_text,
		current_row = 1,
		characters_rendered = 0,

		auto_advance = props.auto_advance, 
		speed = props.speed,
		can_skip = props.can_skip,
	}
	
	local dialogue_mt = {
		__index = function(t: DialogueImpl, k: string): any
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
	log.debug("created text with speed: "..d.speed)

	pt.add(self.active_dialogues, d)

	return d
end

return dialogue_manager
