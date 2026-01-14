local stories = {}


function stories.new_page()
	return {
		type = 'new_page'
	}
end

function stories.chapter_header(text, number)
	return {
		type = 'chapter_header',
		text = text,
		chapter_number = number,
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
	add(intro_node, stories.story_text(text))
	add(intro_node, stories.battle(battle_id, 'victory', 'defeat'))

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
			"militia_spear_captain",
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
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow"
		},
		"Corrupt local militia have allied with bandits!",
		"fortress_town"
	),
	cliff_crossing = stories.chapter_debug(
		{
			"village_hero",
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"child_greatsword",
			"village_axe",
		},
		"Corrupt local militia have allied with bandits!",
		"cliff_crossing"
	),
	demo_story = {
		starting_node = 'prologue',
		nodes = {
			prologue = {
				stories.chapter_header("Prologue"),
				stories.character_customizer(),
				stories.new_page(),
				stories.jump('ch_1_intro')
			},
			ch_1_intro = {
				stories.chapter_header("Homecoming", 1),

				stories.story_text("After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
				stories.story_text("From the distance, songs of battle could be heard.  There could be no mistake, these were the ${bandit_clan} Bandits!"),
				stories.story_text("The ${hero_village} held no militia of its own, so ${hero.name} would need to face the bandit threat on their own."),
				stories.story_text("Prepare for battle!"),

				stories.battle('bandit_village', 'ch_1_v', 'ch_1_f'),
			},
			ch_1_v = {
				stories.story_text("You Win!"),
				stories.jump('ch_2_intro'),
			},
			ch_1_f = {
				stories.story_text(''),
				stories.jump('ch_2_intro'),
			},
			ch_2_intro = {
				stories.chapter_header("Those Who Act in the Shadows", 2),

				stories.story_text("En route to ${town}, ${hero.name}'s party learned of a local cult."),
				stories.story_text("The cult kept a hideout in a nearby cave, where they would hold prisoners for sacrifice."),
				stories.story_text("Though the leader is powerful, the party could at least attemt to free some prisoners before making an escape."),
				stories.story_text("Prepare for battle!"),

				stories.battle('cultist_cave', 'ch_2_v', 'ch_2_f'),
			},
			ch_2_v = {
				stories.story_text("You Win!"),
				stories.jump('ch_3_intro'),
			},
			ch_2_f = {
				stories.story_text('Defeat!'),
				stories.jump('ch_3_intro'),
			},
			ch_3_intro = {
				stories.chapter_header("Homecoming", 3),

				stories.story_text("After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
				stories.story_text("From the distance, songs of battle could be heard.  There could be no mistake, these were the ${bandit_clan} Bandits!"),
				stories.story_text("The ${hero_village} held no militia of its own, so ${hero.name} would need to face the bandit threat on their own."),
				stories.story_text("Prepare for battle!"),

				stories.battle('bandit_village', 'ch_3_v', 'ch_3_f'),
			},
			ch_3_v = {
				stories.story_text("You Win!"),
				stories.jump('ch_4_intro'),
			},
			ch_3_f = {
				stories.story_text(''),
				stories.jump('ch_4_intro'),
			},
		}
	}
}


return {
	data = STORIES,
	default_story = "demo_story",
	story_select = {
		"demo_story",
		"bandit_village",
		"cultist_cave",
		"fortress_town"
	}
}
