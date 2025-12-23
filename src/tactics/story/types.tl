
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
	return {
		type = 'text',
		text = text
	}
end

local record ExitStoryNode
	is StoryNode
	where self.type == 'text'
end

function ExitStoryNode.of(): ExitStoryNode
	return {
		type = 'text',
	}
end

local record RosterAddNode
	is StoryNode
	where self.type == 'roster_add'
	template: string
end

function RosterAddNode.of(template: string): RosterAddNode
	return {
		type = 'roster_add',
		template = template
	}
end

local record BattleNode
	is StoryNode
	where self.type == 'battle'
	battle_id: string
	next_node_victory: NodeId
	next_node_failure: NodeId
end

function BattleNode.of(battle_id: string, next_node_victory: NodeId, next_node_failure: NodeId): BattleNode
	return {
		type = 'battle',
		battle_id = battle_id,
		next_node_victory = next_node_victory,
		next_node_failure = next_node_failure,
	}
end

-- TODO: conditional jumps
local record JumpNode
	is StoryNode
	where self.type == 'jump'
	next_node: NodeId
end

function JumpNode.of(next_node: NodeId): JumpNode
	return {
		type = 'jump',
		next_node = next_node
	}
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
	ExitStoryNode = ExitStoryNode,
	BattleNode = BattleNode,
	JumpNode = JumpNode,
	NewPageNode = NewPageNode,
	RosterAddNode = RosterAddNode,
}
