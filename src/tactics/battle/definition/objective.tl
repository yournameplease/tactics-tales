local battle_objectives = require("src/tactics/battle/objective")


local enum VictoryConditionType
        "rout"
        "defeat_tagged"
        "survive"
        "escape"
end

local interface VictoryCondition
    type: VictoryConditionType
end

local record Rout
    is VictoryCondition
    where self.type == "rout"
end

local record DefeatTagged
    is VictoryCondition
    where self.type == "defeat_tagged"

    tag: string 
end

local record Survive
    is VictoryCondition
    where self.type == "survive"
	turn_limit: integer
end

local record Escape
    is VictoryCondition
    where self.type == "escape"
end

local enum FailureConditionType
    "tagged_player_dies"
    "all_players_die"
    "turn_limit"
end

local interface FailureCondition
    type: FailureConditionType
end

local record TaggedPlayerDies
    is FailureCondition
    where self.type == "tagged_player_dies"
	tag: string
end

local record AllPlayersDie
    is FailureCondition
    where self.type == "all_players_die"
end

local record TurnLimit
    is FailureCondition
    where self.type == "turn_limit"
	turn_limit: integer
end

local battle_objective_definition = {
	VictoryCondition = VictoryCondition,
	FailureCondition = FailureCondition,
}

function battle_objective_definition.to_victory_condition(def: VictoryCondition): battle_objectives.VictoryCondition
	if def is Rout then
		return battle_objectives.rout()
	elseif def is DefeatTagged then
		return battle_objectives.defeat_tagged(def.tag)
	elseif def is Survive then
		return battle_objectives.survive(def.turn_limit)
	elseif def is Escape then
		return battle_objectives.escape()
	else
		unexpected(def.type)
	end
end

function battle_objective_definition.to_failure_condition(def: FailureCondition): battle_objectives.FailureCondition
	if def is AllPlayersDie then
		return battle_objectives.all_players_die()
	elseif def is TaggedPlayerDies then
		return battle_objectives.tagged_player_dies(def.tag)
	elseif def is TurnLimit then
		return battle_objectives.turn_limit(def.turn_limit)
	else
		unexpected(def.type)
	end
end

return battle_objective_definition
