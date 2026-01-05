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

function stories.chapter_debug(
	roster_units,
	text,
	battle_id
)
	local intro_node = {}
	for k,u in ipairs(roster_units) do
		add(intro_node, stories.roster_add(u))
	end
	add(intro_node, stories.story_text("text"))
	add(intro_node, stories.battle('bandit_village', 'victory', 'defeat'))

	return {
		starting_node = 'intro',
		nodes = {
			intro = intro_node,
			victory = {
				stories.story_text("You Win!"),
				stories.exit_story(),
			},
			defeat = {
				stories.story_text("You Lose..."),
				stories.exit_story(),
			},
		}	
	}
end

local STORIES = {
	bandit_village = stories.chapter_debug(
		{
			"village_hero"
		},
		"A young hero finds their village under attack by bandits!",
		"bandit_village"
	),
	cultist_cave = stories.chapter_debug(
		{
			"village_hero",
			"militia_leader",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow"
		},
		"The heros find a cave where cultists keep prisoners for sacrifice.",
		"cultist_cave"
	),
	fortress_town = stories.chapter_debug(
		{
			"village_hero",
			"militia_leader",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow"
		},
		"Corrupt local militia have allied with bandits!",
		"fortress_town"
	),
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
