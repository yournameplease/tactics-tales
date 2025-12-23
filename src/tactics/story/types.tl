
local type StoryId = string
local type NodeId = string

local enum StoryNodeType
	'text'
	'roster_add'
	'battle'
	'jump'
	'new_page'
end

local interface StoryNode
	type: StoryNodeType
end

local record NewPageNode
	is StoryNode
	where self.type == 'new_page'
end

function NewPageNode.of(): NewPageNode
	return {
		type = 'new_page'
	}
end

local record TextNode
	is StoryNode
	where self.type == 'text'
	text: string
end

function TextNode.of(text: string): TextNode
	local self = {
		type = 'text',
		text = text
	}
	return setmetatable(self, { __index = TextNode})
end

local record RosterAddNode
	is StoryNode
	where self.type == 'roster_add'
	template: string
end

function RosterAddNode.of(template: string): RosterAddNode
	local self = {
		type = 'roster_add',
		template = template
	}
	return setmetatable(self, { __index = RosterAddNode})
end

local record BattleNode
	is StoryNode
	where self.type == 'battle'
	battle_id: string
	next_node_victory: NodeId
	next_node_failure: NodeId
end

function BattleNode.of(battle_id: string, next_node_victory: NodeId, next_node_failure: NodeId): BattleNode
	local self = {
		type = 'battle',
		battle_id = battle_id,
		next_node_victory = next_node_victory,
		next_node_failure = next_node_failure,
	}
	return setmetatable(self, { __index = BattleNode})
end

-- TODO: conditional jumps
local record JumpNode
	is StoryNode
	where self.type == 'jump'
	next_node: NodeId
end

function JumpNode.of(next_node: NodeId): JumpNode
	local self = {
		type = 'jump',
		next_node = next_node
	}
	return setmetatable(self, { __index = JumpNode})
end




local record StoryDefinition
	nodes: { string: {StoryNode}}
	starting_node: string
end

return {
	StoryId = StoryId,
	StoryDefinition = StoryDefinition,
	StoryNode = StoryNode,
	StoryNodeType = StoryNodeType,
	TextNode = TextNode,
	BattleNode = BattleNode,
	JumpNode = JumpNode,
	NewPageNode = NewPageNode,
}
