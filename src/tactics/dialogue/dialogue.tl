-- wrapping is separate.  This only gives the raw string
local interface Dialogue
	text: string
	characters_rendered: integer -- non-whitespace
	timer: integer
	timer_limit: integer

	finished: boolean
end

local dialogue = {
	Dialogue = Dialogue
}

return dialogue
