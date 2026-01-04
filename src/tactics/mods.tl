local type ModId = string

local record ModContent
	maps: Path
	battles: Path
	stories: Path
	characters: Path
	items: Path
end

local record ModSpec
	id: ModId
	name: string 
	version: string

	dependendcies: { ModId }

	content: ModContent	
end

local mods = {
	ModId = ModId,
	ModSpec = ModSpec,
}

return mods
