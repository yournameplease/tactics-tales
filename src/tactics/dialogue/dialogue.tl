-- wrapping is separate.  This only gives the raw string
local interface Dialogue
	text: {string}
	current_row: integer
	characters_rendered: integer -- non-whitespace
	timer: integer
	timer_limit: integer

	finished: boolean
end

local dialogue = {
	Dialogue = Dialogue
}

return dialogue
