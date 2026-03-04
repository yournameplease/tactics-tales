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

function stories.save_game()
	return {
		type = 'save_game',
	}
end

function stories.exit_story()
	return {
		type = 'exit_story',
	}
end

function stories.roster_add(template, tags)
	return {
		type = 'roster_add',
		template = template,
		tags = tags,
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

function stories.character_customizer(
	key,
	name_key
)
	return {
		type = 'character_customizer',
		key = key,
		name_key = name_key
	}
end

function stories.text_input(
	text,
	key
)
	return {
		type = 'text_input',
		text = text,
		key = key,
	}
end

function stories.set_memory(key, value)
	return {
		type = 'set_memory',
		key = key,
		value = value,
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
	add(intro_node, stories.roster_add('protagonist', {'hero'}))
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
		{},
		"A young hero finds their village under attack by bandits!",
		"bandit_village"
	),
	cultist_cave = stories.chapter_debug(
		{
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
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"village_hero",
			"militia_spearman",
		},
		"Corrupt local militia have allied with bandits!",
		"fortress_town"
	),
	cliff_crossing = stories.chapter_debug(
		{
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"village_hero",
			"militia_spearman",
			"child_greatsword",
			"village_axe",
		},
		"An unlikely alliance was guarding the cliffside.",
		"cliff_crossing"
	),
	castle_defense = stories.chapter_debug(
		{
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"village_hero",
			"militia_spearman",
			"child_greatsword",
			"village_axe",
		},
		"A three-way alliance is storming the capitol.",
		"castle_defense"
	),
	demo_playground = stories.chapter_debug(
		{},
		"Playground",
		"playground"
	),
	demo_story = {
		starting_node = 'prologue',
		nodes = {
			prologue = {
				stories.chapter_header("Prologue"),
				stories.text_input("This is the story of ${hero_name}", "hero_name"),
				stories.set_memory("hero_village", "Herovillageton"),
				stories.character_customizer("hero", "hero_name"),
				stories.jump('ch_1_intro'),
			},
			ch_1_intro = {
				stories.new_page(),
				stories.chapter_header("Homecoming", 1),

				stories.story_text("After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
				stories.story_text("From the distance, songs of battle could be heard.  There could be no mistake, these were bandits!"),
				stories.story_text("${hero_village} held no militia of its own, so ${hero.name} would need to face the bandit threat alone."),
				stories.story_text("Prepare for battle!"),

				stories.battle('bandit_village', 'ch_1_v', 'ch_1_f'),
			},
			ch_1_v = {
				stories.new_page(),
				stories.save_game(),
				stories.new_page(),
				stories.story_text("After defeating the bandits' leader, ${hero.name} and their newfound allies forced the bandit forces to retreat from ${hero_village}."),
				stories.story_text("The party would proceed to the capitol, to petition for aid in defending against the bandit threat."),
				stories.jump('ch_2_intro'),
			},
			ch_1_f = {
				stories.new_page(),
				stories.story_text("${hero.name} and the visiting militia were no match for the bandits."),
				stories.story_text("${hero_village} would find itself under bandit rule for years to come."),
				stories.jump('game_over'),
			},
			ch_2_intro = {
				stories.new_page(),
				stories.chapter_header("Those Who Act in the Shadows", 2),

				stories.story_text("En route to the capitol, ${hero.name}'s party learned of a local cult."),
				stories.story_text("The cult kept a hideout in a nearby cave, where they would hold prisoners for sacrifice."),
				stories.story_text("Though the leader is powerful, the party could attempt to free some prisoners before making an escape."),
				stories.story_text("Prepare for battle!"),

				stories.battle('cultist_cave', 'ch_2_v', 'ch_2_f'),
			},
			ch_2_v = {
				stories.new_page(),
				stories.save_game(),
				stories.new_page(),
				stories.story_text("You Win!"),
				stories.jump('ch_3_intro'),
			},
			ch_2_f = {
				stories.new_page(),
				stories.story_text("Defeat!"),
				stories.jump('game_over'),
			},
			ch_3_intro = {
				stories.new_page(),
				stories.chapter_header("", 3),

				stories.story_text("As their journey continued, the party reached a fortress town, a final bastion of safety before they could cross bandit-infested cliffs to reach the capitol."),
				stories.story_text("There would be no time for rest, however.  Bandits were laying siege to the fortress."),
				stories.story_text("It made no sense.  The fortress was well guarded."),
				stories.story_text("Why wouldn't the army put up a fight?"),
				stories.story_text("Prepare for battle!"),

				stories.battle('fortress_town', 'ch_3_v', 'ch_3_f'),
			},
			ch_3_v = {
				stories.new_page(),
				stories.save_game(),
				stories.new_page(),

				stories.story_text("Clearly, bandit influence ran deep here."),
				stories.story_text("${hero.name} would need to keep their guard up as they proceeded through the cliffs."),

				stories.jump('ch_4_intro'),
			},
			ch_3_f = {
				stories.new_page(),
				stories.story_text("Defeat!"),
				stories.jump('game_over'),
			},
			ch_4_intro = {
				stories.new_page(),
				stories.chapter_header("Unlikely Alliance", 4),

				stories.story_text("${hero.name} was prepared for bandits when they approached the cliffs."),
				stories.story_text("To their surprise, though, the bandits were not alone this time."),
				stories.story_text("Cultists should hate bandits!  Why were they working together?"),

				stories.story_text("Prepare for battle!"),
				stories.story_text("And watch for rolling rocks!"),

				stories.battle('cliff_crossing', 'ch_4_v', 'ch_4_f'),
			},
			ch_4_v = {
				stories.new_page(),
				stories.save_game(),
				stories.new_page(),

				stories.story_text("Clearly, bandit influence ran deep here."),
				stories.story_text("${hero.name} would need to keep their guard up as they proceeded through the cliffs."),

				stories.jump('ch_5_intro'),
			},
			ch_4_f = {
				stories.new_page(),
				stories.story_text("Defeat!"),
				stories.jump('game_over'),
			},
			ch_5_intro = {
				stories.new_page(),
				stories.chapter_header("Last Stand", 5),

				stories.story_text("At last, ${hero.name} had reached the capitol.  And just in the nick of time."),
				stories.story_text("A three-pronged alliance of bandits, cultists, and defecting milita were assaulting the fortress."),

				stories.story_text("This is it, the final battle!  Protect the monarch!"),
				stories.story_text("Prepare for battle!"),

				stories.battle('castle_defense', 'ch_5_v', 'ch_5_f'),
			},
			ch_5_v = {
				stories.new_page(),
				stories.save_game(),
				stories.new_page(),

				stories.jump('victory'),
			},
			ch_5_f = {
				stories.new_page(),
				stories.story_text("Defeat!"),
				stories.jump('game_over'),
			},
			victory = {
				stories.new_page(),
				stories.chapter_header("Victory"),
				stories.story_text("Congratulations!"),
				stories.story_text("Thank you so much for playing my game.  Please share any feedback you have.  I'm excited to improve the systems and add new content."),
				stories.exit_story(),
			},
			game_over = {
				stories.new_page(),
				stories.chapter_header("Game Over"),
				stories.story_text("Try again.  I believe in you!"),
				stories.exit_story(),
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
		"fortress_town",
		"cliff_crossing",
		"castle_defense",
		"demo_playground",
	}
}
