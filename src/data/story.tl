local Story = require('src/story/types')

global enum StoryId
	"test_story"
end

local STORIES: {StoryId: Story.Story} = {
	test_story = {
		starting_node = 'part_1',
		nodes = {
			part_1 = {
				Story.TextNode.of('text 1.1'),
				Story.TextNode.of('text 1.2'),
				Story.TextNode.of('text 1.3'),
				Story.TextNode.of('text 1.4'),
				Story.TextNode.of('text 1.5'),
				Story.JumpNode.of('part_2')
			},
			part_2 = {
				Story.TextNode.of('text 2.1'),
				Story.TextNode.of('text 2.2'),
				Story.JumpNode.of('part_3')
			},
			part_3 = {
				Story.TextNode.of('text 3.1'),
				Story.BattleNode.of('bandit_village'),
				Story.TextNode.of('text 3.2'),
				Story.JumpNode.of('part_4')
			},
			part_4 = {
				Story.TextNode.of("You Win!")
			}
		}
	}
}


return STORIES
