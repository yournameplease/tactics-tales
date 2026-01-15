-- wrapping is separate.  This only gives the raw string
local interface Dialogue
	text: string
	characters_rendered: integer
	timer: integer
	timer_limit: integer
end

local dialogue = {
	Dialogue = Dialogue
}

return dialogue
