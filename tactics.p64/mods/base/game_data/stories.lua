local stories = {}


function stories.new_page()
	return {
		type = 'new_page'
	}
end

function stories.story_text(text)
	return {
		type = 'text',
		text = text
	}
end

function stories.exit_story()
	return {
		type = 'exit_story',
	}
end

function stories.roster_add(template)
	return {
		type = 'roster_add',
		template = template
	}
end

function stories.battle(battle_id, next_node_victory, next_node_failure)
	return {
		type = 'battle',
		battle_id = battle_id,
		next_node_victory = next_node_victory,
		next_node_failure = next_node_failure,
	}
end

function stories.character_customizer()
	return {
		type = 'character_customizer',
	}
end

function stories.jump(next_node)
	return {
		type = 'jump',
		next_node = next_node
	}
end

local STORIES = {
	bandit_village = {
		starting_node = 'intro',
		nodes = {
			intro = {
				stories.roster_add("village_hero"),
				stories.story_text("A young hero finds their village under attack by bandits!"),
				stories.battle('bandit_village', 'victory', 'defeat'),
			},
			victory = {
				stories.story_text("You Win!"),
				stories.exit_story(),
			},
			defeat = {
				stories.story_text("You Lose..."),
				stories.exit_story(),
			},
		}	
	},
	cultist_cave = {
		starting_node = 'intro',
		nodes = {
			intro = {
				stories.roster_add("village_hero"),
				stories.roster_add("militia_leader"),
				stories.roster_add("militia_spearman"),
				stories.roster_add("militia_armor"),
				stories.roster_add("militia_archer"),
				stories.story_text("The heros find a cave where cultists keep prisoners for sacrifice."),
				stories.battle('cultist_cave', 'victory', 'defeat'),
			},
			victory = {
				stories.story_text("You Win!"),
				stories.exit_story(),

			},
			defeat = {
				stories.story_text("You Lose..."),
				stories.exit_story(),
			},
		}	
	},
	test_story = {
		starting_node = 'part_1',
		nodes = {
			part_1 = {
				stories.character_customizer(),
				stories.new_page(),
				stories.story_text("This is a lot of text.  A whooooooooooooooooooooooooooooooooooooooole lot.  To trigger screenwrap."),
				stories.story_text('Thisisalotoftext.Awhooooooooooooooooooooooooooooooooooooooolelot.Totriggerhyphenation.'),
				stories.story_text('text 1.3'),
				stories.story_text('text 1.4'),
				stories.jump('part_3')
			},
			part_3 = {
				stories.story_text('text 3.1'),
				stories.battle('bandit_village', 'part_4_v', 'part_4_f'),
				stories.story_text('text 3.2'),
				stories.jump('part_4')
			},
			part_4_v = {
				stories.story_text("You Win!"),
				stories.jump('part_5'),
			},
			part_4_f = {
				stories.story_text("You Lose..."),
				stories.jump('part_5'),
			},
			part_5 = {
				stories.story_text("Restarting the story"),
				stories.new_page(),
				stories.jump('part_1')
			},
		}
	}
}


return STORIES
