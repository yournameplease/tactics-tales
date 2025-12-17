

-- Game Context which can be passed among children for a mode,
-- and helps to exposes information to the UI 

global type GameServiceBundle

global enum GameContextType
    "game"
    "battle"
    "story"
end

global interface GameContext
	type: GameContextType
	-- I don't like this here but it is convenient
	-- Use sparringly!!!
	services: GameServiceBundle
end
