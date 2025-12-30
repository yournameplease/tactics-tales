local story_types = require('src/tactics/story/types')
local story_node = story_types.story_node

local STORIES: {story_types.StoryId: story_types.StoryDefinition} = {
	bandit_village = {
		starting_node = 'intro',
		nodes = {
			intro = {
				story_node.roster_add("village_hero"),
				story_node.story_text("A young hero finds their village under attack by bandits!"),
				story_node.battle('bandit_village', 'victory', 'defeat'),
			},
			victory = {
				story_node.story_text("You Win!"),
				story_node.exit_story(),
			},
			defeat = {
				story_node.story_text("You Lose..."),
				story_node.exit_story(),
			},
		}	
	},
	cultist_cave = {
		starting_node = 'intro',
		nodes = {
			intro = {
				story_node.roster_add("village_hero"),
				story_node.roster_add("militia_leader"),
				story_node.roster_add("militia_spearman"),
				story_node.roster_add("militia_armor"),
				story_node.roster_add("militia_archer"),
				story_node.story_text("The heros find a cave where cultists keep prisoners for sacrifice."),
				story_node.battle('cultist_cave', 'victory', 'defeat'),
			},
			victory = {
				story_node.story_text("You Win!"),
				story_node.exit_story(),

			},
			defeat = {
				story_node.story_text("You Lose..."),
				story_node.exit_story(),
			},
		}	
	},
	test_story = {
		starting_node = 'part_1',
		nodes = {
			part_1 = {
				story_node.character_customizer(),
				story_node.new_page(),
				story_node.story_text("This is a lot of text.  A whooooooooooooooooooooooooooooooooooooooole lot.  To trigger screenwrap."),
				story_node.story_text('Thisisalotoftext.Awhooooooooooooooooooooooooooooooooooooooolelot.Totriggerhyphenation.'),
				story_node.story_text('text 1.3'),
				story_node.story_text('text 1.4'),
				story_node.jump('part_3')
			},
			part_3 = {
				story_node.story_text('text 3.1'),
				story_node.battle('bandit_village', 'part_4_v', 'part_4_f'),
				story_node.story_text('text 3.2'),
				story_node.jump('part_4')
			},
			part_4_v = {
				story_node.story_text("You Win!"),
				story_node.jump('part_5'),
			},
			part_4_f = {
				story_node.story_text("You Lose..."),
				story_node.jump('part_5'),
			},
			part_5 = {
				story_node.story_text("Restarting the story"),
				story_node.new_page(),
				story_node.jump('part_1')
			},
		}
	}
}


return STORIES
