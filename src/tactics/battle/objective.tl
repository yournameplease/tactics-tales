local bm = require("src/tactics/battle/battle_map")
local BattleUnit = require("src/tactics/battle/tactics/battle_unit").BattleUnit

local interface VictoryCondition
	text: string
	check: function(self, battle_map: bm.BattleMap, turn_limit_exceeded: boolean): boolean
end

local record Rout
    is VictoryCondition
end

function Rout:check(battle_map: bm.BattleMap, _turn_limit_exceeded: boolean): boolean
    local enemies = battle_map:get_units(BattleUnit.is_enemy)
    return #enemies == 0
end

local record DefeatTagged
    is VictoryCondition
    tag: string 
end

function DefeatTagged:check(battle_map: bm.BattleMap, _turn_limit_exceeded: boolean): boolean
    local enemies = battle_map:get_units(function(unit: BattleUnit): boolean
		return unit:is_enemy() and unit.tags[self.tag]
	end)
    return #enemies == 0
end

local record Survive
    is VictoryCondition
end

function Survive:check(_battle_map: bm.BattleMap, turn_limit_exceeded: boolean): boolean
	return turn_limit_exceeded
end

local record Escape
    is VictoryCondition
end

function Escape:check(battle_map: bm.BattleMap, _turn_limit_exceeded: boolean): boolean
    local players = battle_map:get_units(BattleUnit.is_player)
    return #players == 0
end

local interface FailureCondition
	text: string
	check: function(self, battle_map: bm.BattleMap, turn_limit_exceeded: boolean): boolean
end

local record AllPlayersDie
	is FailureCondition
end

function AllPlayersDie:check(battle_map: bm.BattleMap, _turn_limit_exceeded: boolean): boolean
    local players = battle_map:get_units(BattleUnit.is_player)
    return #players == 0
end

local record TaggedPlayerDies
	is FailureCondition
	tag: string
end

function TaggedPlayerDies:check(battle_map: bm.BattleMap, _turn_limit_exceeded: boolean): boolean
	-- todo: this checks that all tagged players are dead
	-- move to a script if we need to check any one dies
    local players = battle_map:get_units(function(unit: BattleUnit): boolean
		return unit:is_player() and unit.tags[self.tag]
	end)
    return #players == 0
end

local record TurnLimit
	is FailureCondition
end

function TurnLimit:check(_battle_map: bm.BattleMap, turn_limit_exceeded: boolean): boolean
	return turn_limit_exceeded
end

local battle_objectives = {
	VictoryCondition = VictoryCondition,
	FailureCondition = FailureCondition,
}

function battle_objectives.rout(text: string): VictoryCondition
    local self: Rout = setmetatable({
		text = text,
    }, { __index = Rout})
    return self
end

function battle_objectives.defeat_tagged(text: string, tag: string): VictoryCondition
    local self: DefeatTagged = setmetatable({
		text = text,
        tag = tag,
    }, { __index = DefeatTagged})
    return self
end

function battle_objectives.survive(text: string): VictoryCondition
    local self: Survive = setmetatable({
		text = text,
    }, { __index = Survive})
    return self
end

function battle_objectives.escape(text: string): VictoryCondition
    local self: Escape = setmetatable({
		text = text,
    }, { __index = Escape})
    return self
end

function battle_objectives.all_players_die(text: string): FailureCondition
    local self: AllPlayersDie = setmetatable({
		text = text,
    }, { __index = AllPlayersDie})
    return self
end

function battle_objectives.tagged_player_dies(text: string, tag: string): FailureCondition
    local self: TaggedPlayerDies = setmetatable({
		text = text,
		tag = tag
    }, { __index = TaggedPlayerDies})
    return self
end

function battle_objectives.turn_limit(text: string): FailureCondition
    local self: TurnLimit = setmetatable({
		text = text,
    }, { __index = TurnLimit })
    return self
end

return battle_objectives
