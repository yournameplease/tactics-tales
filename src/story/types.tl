
local enum StoryNodeType
	'text'
	'battle'
	'jump'
end

local interface StoryNode
	type: StoryNodeType
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

local record BattleNode
	is StoryNode
	where self.type == 'battle'
	battle_id: string
end

function BattleNode.of(battle_id: string): BattleNode
	local self = {
		type = 'battle',
		battle_id = battle_id
	}
	return setmetatable(self, { __index = BattleNode})
end

-- TODO: conditional jumps
local record JumpNode
	is StoryNode
	where self.type == 'jump'
	next_node: string
end

function JumpNode.of(next_node: string): JumpNode
	local self = {
		type = 'jump',
		next_node = next_node
	}
	return setmetatable(self, { __index = JumpNode})
end




local record Story
	nodes: { string: {StoryNode}}
	starting_node: string
end

return {
	Story = Story,
	StoryNode = StoryNode,
	TextNode = TextNode,
	BattleNode = BattleNode,
	JumpNode = JumpNode,
}
