local StoryTypes = require('src/story/types')

local STORIES: {StoryTypes.StoryId: StoryTypes.StoryDefinition} = {
	test_story = {
		starting_node = 'part_1',
		nodes = {
			part_1 = {
				StoryTypes.TextNode.of("This is a lot of text.  A whooooooooooooooooooooooooooooooooooooooole lot.  To trigger screenwrap."),
				StoryTypes.TextNode.of('Thisisalotoftext.Awhooooooooooooooooooooooooooooooooooooooolelot.Totriggerhyphenation.'),
				StoryTypes.TextNode.of('text 1.3'),
				StoryTypes.TextNode.of('text 1.4'),
				StoryTypes.JumpNode.of('part_2')
			},
			part_2 = {
				StoryTypes.NewPageNode.of(),
				StoryTypes.TextNode.of('text 2.1'),
				StoryTypes.TextNode.of('text 2.2'),
				StoryTypes.JumpNode.of('part_3')
			},
			part_3 = {
				StoryTypes.TextNode.of('text 3.1'),
				StoryTypes.BattleNode.of('bandit_village', 'part_4_v', 'part_4_f'),
				StoryTypes.NewPageNode.of(),
				StoryTypes.TextNode.of('text 3.2'),
				StoryTypes.JumpNode.of('part_4')
			},
			part_4_v = {
				StoryTypes.TextNode.of("You Win!"),
				StoryTypes.JumpNode.of('part_5'),
			},
			part_4_f = {
				StoryTypes.TextNode.of("You Lose..."),
				StoryTypes.JumpNode.of('part_5'),
			},
			part_5 = {
				StoryTypes.TextNode.of("Restarting the story"),
				StoryTypes.NewPageNode.of(),
				StoryTypes.JumpNode.of('part_1')
			},
		}
	}
}


return STORIES
