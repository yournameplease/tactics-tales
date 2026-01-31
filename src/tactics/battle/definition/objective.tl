local battle_objectives = require("src.tactics.battle.objective")


local enum VictoryConditionType
        "rout"
        "defeat_tagged"
        "survive"
        "escape"
end

local interface VictoryCondition
    type: VictoryConditionType
	text: string -- nillable
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
end

local record Escape
    is VictoryCondition
    where self.type == "escape"
end

local enum FailureConditionType
    "tagged_unit_dies"
    "all_players_die"
    "turn_limit"
end

local interface FailureCondition
    type: FailureConditionType
	text: string -- nillable
end

local record TaggedPlayerDies
    is FailureCondition
    where self.type == "tagged_unit_dies"
	tag: string
end

local record AllPlayersDie
    is FailureCondition
    where self.type == "all_players_die"
end

local record TurnLimit
    is FailureCondition
    where self.type == "turn_limit"
end

local battle_objective_definition = {
	VictoryCondition = VictoryCondition,
	FailureCondition = FailureCondition,
}

function battle_objective_definition.to_victory_condition(def: VictoryCondition): battle_objectives.VictoryCondition
	if def is Rout then
		return battle_objectives.rout(def.text)
	elseif def is DefeatTagged then
		return battle_objectives.defeat_tagged(def.text, def.tag)
	elseif def is Survive then
		return battle_objectives.survive(def.text)
	elseif def is Escape then
		return battle_objectives.escape(def.text)
	else
		unexpected(def.type)
	end
end

function battle_objective_definition.to_failure_condition(def: FailureCondition): battle_objectives.FailureCondition
	if def is AllPlayersDie then
		return battle_objectives.all_players_die(def.text)
	elseif def is TaggedPlayerDies then
		return battle_objectives.tagged_player_dies(def.text, def.tag)
	elseif def is TurnLimit then
		return battle_objectives.turn_limit(def.text)
	else
		unexpected(def.type)
	end
end

return battle_objective_definition
