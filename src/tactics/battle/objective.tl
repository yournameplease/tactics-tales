local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local BattleUnit = require("src/tactics/battle/tactics/battle_unit").BattleUnit

local interface VictoryCondition
	check: function(self, battle_map: BattleMap, turn_number: integer): boolean
end

local record Rout
    is VictoryCondition
end

function Rout:check(battle_map: BattleMap, _turn_number: integer): boolean
    local enemies = battle_map:get_units(BattleUnit.is_enemy)
    return #enemies == 0
end

local record DefeatTagged
    is VictoryCondition
    tag: string 
end

function DefeatTagged:check(battle_map: BattleMap, _turn_number: integer): boolean
    local enemies = battle_map:get_units(function(unit: BattleUnit): boolean
		return unit:is_enemy() and unit.labels[self.tag]
	end)
    return #enemies == 0
end

local record Survive
    is VictoryCondition
    turn_limit: integer 
end

function Survive:check(_battle_map: BattleMap, turn_number: integer): boolean
    return turn_number > self.turn_limit
end

local record Escape
    is VictoryCondition
end

function Escape:check(battle_map: BattleMap, _turn_number: integer): boolean
    local players = battle_map:get_units(BattleUnit.is_player)
    return #players == 0
end

local interface FailureCondition
	check: function(self, battle_map: BattleMap, turn_number: integer): boolean
end

local record AllPlayersDie
	is FailureCondition
end

function AllPlayersDie:check(battle_map: BattleMap, _turn_number: integer): boolean
    local players = battle_map:get_units(BattleUnit.is_player)
    return #players == 0
end

local record TaggedPlayerDies
	is FailureCondition
	tag: string
end

-- function TaggedPlayerDies:check(battle_map: BattleMap, turn_number: integer): boolean
-- 	todo()
-- end

local record TurnLimit
	is FailureCondition
	turn_limit: integer
end

function TurnLimit:check(_battle_map: BattleMap, turn_number: integer): boolean
	return turn_number >= self.turn_limit
end

local battle_objectives = {
	VictoryCondition = VictoryCondition,
	FailureCondition = FailureCondition,
}

function battle_objectives.rout(): VictoryCondition
    local self: Rout = setmetatable({
    }, { __index = Rout})
    return self
end

function battle_objectives.defeat_tagged(tag: string): VictoryCondition
    local self: DefeatTagged = setmetatable({
        tag = tag,
    }, { __index = DefeatTagged})
    return self
end

function battle_objectives.survive(turn_limit: integer): VictoryCondition
    local self: Survive = setmetatable({
        turn_limit = turn_limit,
    }, { __index = Survive})
    return self
end

function battle_objectives.escape(): VictoryCondition
    local self: Escape = setmetatable({
    }, { __index = Escape})
    return self
end

function battle_objectives.all_players_die(): FailureCondition
    local self: AllPlayersDie = setmetatable({
    }, { __index = AllPlayersDie})
    return self
end

function battle_objectives.tagged_player_dies(tag: string): FailureCondition
    local self: TaggedPlayerDies = setmetatable({
		tag = tag
    }, { __index = TaggedPlayerDies})
    return self
end

function battle_objectives.turn_limit(turn_limit: integer): FailureCondition
    local self: TurnLimit = setmetatable({
        turn_limit = turn_limit,
    }, { __index = TurnLimit })
    return self
end

return battle_objectives
