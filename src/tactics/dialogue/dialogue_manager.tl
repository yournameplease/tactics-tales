local dialogue = require("src/tactics/dialogue/dialogue")
local Dialogue = dialogue.Dialogue

local InputContext = require("src/tactics/input/input_context").InputContext

local record DialogueProps
	speed: DialogueSpeed
	can_skip: boolean
end

local interface DialogueManager
	update: function(self, input: InputContext)
	create_dialogue: function(
		self,
		text: string,
		props: DialogueProps,
		replacement_vars: {string: string}
	): Dialogue
end

local record DialogueImpl
	is Dialogue
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

function DialogueManagerImpl:update(_: InputContext)
	self.global_timer = self.global_timer + 1

	for _,d in ipairs(self.active_dialogues) do
		if d.characters_rendered < #d.text and d.timer == 0 then
			local mask = SPEED_MASK[d.speed]
			if mask > 0 then
				d.characters_rendered = d.characters_rendered + 1
			else
				d.characters_rendered = d.characters_rendered + -mask
			end
		end
	end
end

local function time_at_speed(timer: integer, speed: DialogueSpeed): integer
	local mask = SPEED_MASK[speed]
	return mask > 0
		and timer & mask
		or 0
end

function DialogueManagerImpl:create_dialogue(
	text: string,
	props: DialogueProps,
	replacement_vars: {string: string}
): Dialogue
	local replaced_text = string.gsub(
		text,
		"${([%w_%.]+)}",
		function(key: string): string
			local val = replacement_vars[key]
			if val == nil then
				return "[MISSING KEY: "..key.."]"
			end
			return val
		end
	)
	
	local d: DialogueImpl = {
		text = replaced_text,
		characters_rendered = 0,

		speed = props.speed,
		can_skip = props.can_skip,
	}
	local dialogue_mt = {
		__index = function(_t: DialogueImpl, k: string): any
			if k == "speed" then
				return DYNAMIC_CONFIG.dialogue_speed
			end
			if k == "timer" then
				return time_at_speed(self.global_timer - d.timer_offset, d.speed)
			end
			if k == "timer_limit" then
				return SPEED_MASK[d.speed] + 1
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
