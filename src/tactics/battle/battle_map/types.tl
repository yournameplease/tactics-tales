-- used by interaction scripts
local enum TileDistance
	"on"
	"adjacent"
end

local interface InteractionHook
    script_id: integer 
    interaction_text: string
end

local record TileInteractionHook
	is InteractionHook
    script_id: integer 
    interaction_text: string
    interaction_distance: TileDistance
end

local record UnitInteractionHook
	is InteractionHook
    script_id: integer 
    interaction_text: string
end

return {
	TileDistance = TileDistance,
	TileInteractionHook = TileInteractionHook,
	UnitInteractionHook = UnitInteractionHook,
	InteractionHook = InteractionHook,
}


