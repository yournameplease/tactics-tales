local StoryTypes = require('src/tactics/story/types')

local STORIES: {StoryTypes.StoryId: StoryTypes.StoryDefinition} = {
	bandit_village = {
		starting_node = 'intro',
		nodes = {
			intro = {
				StoryTypes.RosterAddNode.of("village_hero"),
				StoryTypes.StoryTextNode.of("A young hero finds their village under attack by bandits!"),
				StoryTypes.BattleNode.of('bandit_village', 'victory', 'defeat'),
			},
			victory = {
				StoryTypes.StoryTextNode.of("You Win!"),
				StoryTypes.ExitStoryNode.of(),
			},
			defeat = {
				StoryTypes.StoryTextNode.of("You Lose..."),
				StoryTypes.ExitStoryNode.of(),
			},
		}	
	},
	cultist_cave = {
		starting_node = 'intro',
		nodes = {
			intro = {
				StoryTypes.RosterAddNode.of("village_hero"),
				StoryTypes.RosterAddNode.of("militia_leader"),
				StoryTypes.RosterAddNode.of("militia_spearman"),
				StoryTypes.RosterAddNode.of("militia_armor"),
				StoryTypes.RosterAddNode.of("militia_archer"),
				StoryTypes.StoryTextNode.of("The heros find a cave where cultists keep prisoners for sacrifice."),
				StoryTypes.BattleNode.of('cultist_cave', 'victory', 'defeat'),
			},
			victory = {
				StoryTypes.StoryTextNode.of("You Win!"),
				StoryTypes.ExitStoryNode.of(),

			},
			defeat = {
				StoryTypes.StoryTextNode.of("You Lose..."),
				StoryTypes.ExitStoryNode.of(),
			},
		}	
	},
	test_story = {
		starting_node = 'part_1',
		nodes = {
			part_1 = {
				StoryTypes.RosterAddNode.of("village_hero"),
				StoryTypes.StoryTextNode.of("This is a lot of text.  A whooooooooooooooooooooooooooooooooooooooole lot.  To trigger screenwrap."),
				StoryTypes.StoryTextNode.of('Thisisalotoftext.Awhooooooooooooooooooooooooooooooooooooooolelot.Totriggerhyphenation.'),
				StoryTypes.StoryTextNode.of('text 1.3'),
				StoryTypes.StoryTextNode.of('text 1.4'),
				StoryTypes.JumpNode.of('part_2')
			},
			part_2 = {
				StoryTypes.NewPageNode.of(),
				StoryTypes.StoryTextNode.of('text 2.1'),
				StoryTypes.StoryTextNode.of('text 2.2'),
				StoryTypes.JumpNode.of('part_3')
			},
			part_3 = {
				StoryTypes.StoryTextNode.of('text 3.1'),
				StoryTypes.BattleNode.of('bandit_village', 'part_4_v', 'part_4_f'),
				StoryTypes.NewPageNode.of(),
				StoryTypes.StoryTextNode.of('text 3.2'),
				StoryTypes.JumpNode.of('part_4')
			},
			part_4_v = {
				StoryTypes.StoryTextNode.of("You Win!"),
				StoryTypes.JumpNode.of('part_5'),
			},
			part_4_f = {
				StoryTypes.StoryTextNode.of("You Lose..."),
				StoryTypes.JumpNode.of('part_5'),
			},
			part_5 = {
				StoryTypes.StoryTextNode.of("Restarting the story"),
				StoryTypes.NewPageNode.of(),
				StoryTypes.JumpNode.of('part_1')
			},
		}
	}
}


return STORIES
