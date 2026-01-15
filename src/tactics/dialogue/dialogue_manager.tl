local dialogue = require("src/tactics/dialogue/dialogue")
local Dialogue = dialogue.Dialogue

local InputContext = require("src/tactics/input/input_context").InputContext

local record DialogueProps
	speed: DialogueSpeed
	can_skip: boolean
end

local interface DialogueManager
	update: function(self, input: InputContext)
	create_dialogue: function(self, text: string, props: DialogueProps): Dialogue
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

function DialogueManagerImpl:update(_: InputContext)
	self.global_timer = self.global_timer + 1
end

local SPEED_MASK <total>: {DialogueSpeed: integer} = {
	slow = 0x8,
	normal = 0x10,
	fast = 0x4,
	instant = 0x0,
}

local function time_at_speed(timer: integer, speed: DialogueSpeed): integer
	return timer & SPEED_MASK[speed]
end

function DialogueManagerImpl:create_dialogue(
	text: string,
	props: DialogueProps
): Dialogue
	local d: DialogueImpl = {
		text = text,
		characters_rendered = 0,

		speed = props.speed,
		can_skip = props.can_skip,
	}
	local dialogue_mt = {
		__index = function(t: DialogueImpl, k: string): any
			if k == "speed" and t.speed == nil then
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
	d.timer_offset = time_at_speed(self.global_timer, d.speed)

	setmetatable(d, dialogue_mt)

	pt.add(self.active_dialogues, d)

	return d
end
