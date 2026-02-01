---@desc Specification for game mods.
--- Note that reference fields may be provided by dependent mods as well
--- Used for mod validation
local s = require("src.tactics.validator.schema_definition")


local base_spec = s.record({
	id = s.string(),
	name = s.optional(s.string()),
	version = s.optional(s.string()),
	dependendcies = s.string(),
	content = s.string(),
})
