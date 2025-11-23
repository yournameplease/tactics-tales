local GameContext = {}

function GameContext.new(
    tactics,
    turn_manager,
    tile_manager,
    character_manager
)
    return {
        tactics = tactics,
        turn_manager = turn_manager,
        tile_manager = tile_manager,
        character_manager = character_manager,
    }
end

return GameContext