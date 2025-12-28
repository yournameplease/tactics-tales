
local type StoryId = string
local type NodeId = string

local enum StoryNodeType
	'text'
	'roster_add'
	'battle'
	'jump'
	'new_page'
	'character_customizer'
end

local interface StoryNode
	type: StoryNodeType
end

local record NewPageNode
	is StoryNode
	where self.type == 'new_page'
end

local record StoryTextNode
	is StoryNode
	where self.type == 'text'
	text: string
end

local record ExitStoryNode
	is StoryNode
	where self.type == 'text'
end

local record RosterAddNode
	is StoryNode
	where self.type == 'roster_add'
	template: string
end

local record BattleNode
	is StoryNode
	where self.type == 'battle'
	battle_id: string
	next_node_victory: NodeId
	next_node_failure: NodeId
end

local record CharacterCustomizerNode
	is StoryNode
	where self.type == 'character_customizer'
end

-- TODO: conditional jumps
local record JumpNode
	is StoryNode
	where self.type == 'jump'
	next_node: NodeId
end

local story_node = {
	StoryNode = StoryNode,
	StoryNodeType = StoryNodeType,
	StoryTextNode = StoryTextNode,
	ExitStoryNode = ExitStoryNode,
	BattleNode = BattleNode,
	JumpNode = JumpNode,
	NewPageNode = NewPageNode,
	RosterAddNode = RosterAddNode,
	CharacterCustomizerNode = CharacterCustomizerNode,
}

function story_node.new_page(): NewPageNode
	return {
		type = 'new_page'
	}
end

function story_node.story_text(text: string): StoryTextNode
	return {
		type = 'text',
		text = text
	}
end

function story_node.exit_story(): ExitStoryNode
	return {
		type = 'text',
	}
end

function story_node.roster_add(template: string): RosterAddNode
	return {
		type = 'roster_add',
		template = template
	}
end

function story_node.battle(battle_id: string, next_node_victory: NodeId, next_node_failure: NodeId): BattleNode
	return {
		type = 'battle',
		battle_id = battle_id,
		next_node_victory = next_node_victory,
		next_node_failure = next_node_failure,
	}
end

function story_node.character_customizer(): CharacterCustomizerNode
	return {
		type = 'character_customizer',
	}
end

function story_node.jump(next_node: NodeId): JumpNode
	return {
		type = 'jump',
		next_node = next_node
	}
end


local record StoryDefinition
	nodes: { string: {StoryNode}}
	starting_node: string
end

local story_types = {
	StoryId = StoryId,
	StoryDefinition = StoryDefinition,
	story_node = story_node
}

return story_types
