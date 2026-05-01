local campaigns = {}

---@param config BattleConfigInput
---@return fun(StoryConfig): BattleConfig
local function static_battle_config(config)
	return function()
		return {
			permadeath = config.permadeath or true
		}
	end
end

function campaigns.new_page()
	return {
		type = 'new_page'
	}
end

function campaigns.chapter_header(text, number)
	return {
		type = 'chapter_header',
		text = text,
		chapter_number = number,
	}
end

function campaigns.story_text(text)
	return {
		type = 'text',
		text = text
	}
end

function campaigns.save_game()
	return {
		type = 'save_game',
	}
end


function campaigns.delete_file()
	return {
		type = 'delete_file',
	}
end

function campaigns.advance()
	return {
		type = 'advance',
	}
end

function campaigns.exit_campaign()
	return {
		type = 'exit_campaign',
	}
end

function campaigns.game_results()
	return {
		type = 'game_results',
	}
end

function campaigns.roster_add(template, tags)
	return {
		type = 'roster_add',
		template = template,
		tags = tags,
	}
end

function campaigns.battle(battle_id, next_node_victory, next_node_failure)
	return {
		type = 'battle',
		battle_id = battle_id,
		next_node_victory = next_node_victory,
		next_node_failure = next_node_failure,
	}
end

function campaigns.character_customizer(
	key,
	name_key
)
	return {
		type = 'character_customizer',
		key = key,
		name_key = name_key
	}
end

function campaigns.text_input(
	text,
	key
)
	return {
		type = 'text_input',
		text = text,
		key = key,
	}
end

function campaigns.set_memory(key, value)
	return {
		type = 'set_memory',
		key = key,
		value = value,
	}
end

function campaigns.jump(next_node)
	return {
		type = 'jump',
		next_node = next_node
	}
end

function campaigns.detour(target)
	return {
		type = 'detour',
		target = target,
	}
end

function campaigns.select_option(options, memory_key)
	return {
		type = 'select_option',
		options = options,
		memory_key = memory_key,
	}
end

---@param roster_units string[]
---@param name string
---@param text string
---@param battle_id BattleId
---@return BattleDefinition
function campaigns.chapter_debug(
	roster_units,
	name,
	text,
	battle_id
)
	local intro_node = {}
	add(intro_node, campaigns.roster_add('protagonist', {'hero'}))
	for k,u in ipairs(roster_units) do
		add(intro_node, campaigns.roster_add(u))
	end
	add(intro_node, campaigns.story_text(text))
	add(intro_node, campaigns.battle(battle_id, 'victory', 'defeat'))

	return {
		starting_node = 'intro',
		name = name,
		description = text or "A single chapter.",
		battle_config = static_battle_config{
			permadeath = true,
		},
		nodes = {
			intro = intro_node,
			victory = {
				campaigns.story_text("You Win!"),
				campaigns.game_results(),
				campaigns.exit_campaign(),
			},
			defeat = {
				campaigns.story_text("You Lose..."),
				campaigns.game_results(),
				campaigns.exit_campaign(),
			},
		}
	}
end

local GENERIC_CONFIG = {
	options = {
		{
			key = "turn_difficulty",
			name = "Turn difficulty",
			description = "How much time you are given to complete chapters. Exceeding the turn limit will result in a failure.",
			options = {
				{
					name = "Easy",
					value = "easy",
					description = "Most chapters will have no turn limit."
				},
				{
					name = "Normal",
					value = "normal",
					description = "Chapters will have a reasonable turn limit.",
				},
				{
					name = "Hard",
					value = "hard",
					description = "Chapters will have difficult turn limits. Good for repeat playthroughs."
				},
			}
		},
		{
			key = "saving",
			name = "Save Behavior",
			description = "How to handle saving after a battle ends.",
			options = {
				{
					name = "Normal",
					value = "ask",
					description = "After each victory, choose whether to save.",
				},
				{
					name = "Ironman",
					value = "ironman",
					description = "Save after the end of each battle.",
				},
				{
					name = "Hardcore",
					value = "hardcore",
					description = "Save after the end of each battle. Delete the file on defeat.",
				},
			}
		},
		{
			key = "deaths",
			name = "Death Behavior",
			description = "How to handle player unit deaths.",
			options = {
				{
					name = "Classic",
					value = "classic",
					description = "Units will die permanently.",
				},
				{
					name = "Casual",
					value = "casual",
					description = "Units will retreat and return in the next chapter.",
				},
			}
		},
	},
	presets = {
		{
			key = "easy",
			name = "Easy",
			values = { turn_difficulty = "easy", saving = "ask", deaths = "casual" },
		},
		{
			key = "normal",
			name = "Normal",
			values = { turn_difficulty = "normal", saving = "ironman", deaths = "classic" },
		},
		{
			key = "hard",
			name = "Hard",
			values = { turn_difficulty = "hard", saving = "hardcore", deaths = "classic" },
		},
	},
	default_preset = "normal",
}

local STORIES = {
	bandit_village = campaigns.chapter_debug(
		{},
		"Chapter 1: Bandit Village",
		"A young hero finds their village under attack by bandits!",
		"bandit_village"
	),
	cultist_cave = campaigns.chapter_debug(
		{
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow"
		},
		"Chapter 2: Cultist Cave",
		"The heros find a cave where cultists keep prisoners for sacrifice.",
		"cultist_cave"
	),
	fortress_town = campaigns.chapter_debug(
		{
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"village_hero",
			"militia_spearman",
			"bandit_nerd",
		},
		"Chapter 3: Fortress Town",
		"Corrupt local militia have allied with bandits!",
		"fortress_town"
	),
	cliff_crossing = campaigns.chapter_debug(
		{
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"village_hero",
			"militia_spearman",
			"bandit_nerd",
			"child_greatsword",
			"village_axe",
		},
		"Chapter 4: Cliff Crossing",
		"An unlikely alliance was guarding the cliffside.",
		"cliff_crossing"
	),
	castle_defense = campaigns.chapter_debug(
		{
			"militia_spear_captain",
			"militia_spearman",
			"militia_armor",
			"militia_archer",
			"child_axe",
			"child_bow",
			"village_hero",
			"militia_spearman",
			"bandit_nerd",
			"child_greatsword",
			"village_axe",
		},
		"Chapter 5: Castle Defense",
		"A three-way alliance is storming the capitol.",
		"castle_defense"
	),
	demo_playground = campaigns.chapter_debug(
		{},
		"Playground",
		"Various characters to assist in debugging.",
		"playground"
	),
	model_room = campaigns.chapter_debug(
		{},
		"Model Room",
		"A lot of randomly generated characters.",
		"model_room"
	),
	convention_demo = {
		starting_node = 'prologue',
		name = 'Tactics Tales Fantasy',
		description = "A simple story of bandits, cultists, and evil armies. Lead a band of heroes after bandits attack your village.",
		config = GENERIC_CONFIG,
		battle_config = static_battle_config{
			permadeath = true,
		},
		nodes = {
			prologue = {
				campaigns.chapter_header("Tactics Tales"),
				campaigns.text_input("This is the story of ${hero_name}", "hero_name"),
				campaigns.set_memory("hero_village", "Herovillageton"),
				campaigns.character_customizer("hero", "hero_name"),
				campaigns.jump('ch_1_intro'),
			},
			ch_1_intro = {
				campaigns.new_page(),

				campaigns.story_text("After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
				campaigns.story_text("From the distance, songs of battle could be heard.  There could be no mistake, these were bandits!"),
				campaigns.story_text("${hero_village} held no militia of its own, so ${hero.name} would need to face the bandit threat alone."),
				campaigns.story_text("Prepare for battle!"),

				campaigns.battle('bandit_village', 'ch_1_v', 'ch_1_f'),
			},
			ch_1_v = {
				campaigns.new_page(),
				campaigns.story_text("After defeating the bandits' leader, ${hero.name} and their newfound allies forced the bandit forces to retreat from ${hero_village}."),
				campaigns.story_text("The party would proceed to the capitol, to petition for aid in defending against the bandit threat."),
				campaigns.story_text("But you'll need to play the full game to see that!"),
				campaigns.story_text("Check it out at \nyour-name-please.itch.io/tactics-tales!"),
				campaigns.exit_campaign(),
			},
			ch_1_f = {
				campaigns.new_page(),
				campaigns.story_text("${hero.name} and the visiting militia were no match for the bandits."),
				campaigns.story_text("${hero_village} would find itself under bandit rule for years to come."),
				campaigns.story_text("Try again for a victory. I believe in you!"),
				campaigns.story_text("Or, play the full game at \nyour-name-please.itch.io/tactics-tales!"),
				campaigns.exit_campaign(),
			},
		},
	},
	demo_story = {
		starting_node = 'prologue',
		name = 'Tactics Tales Fantasy',
		description = "A simple story of bandits, cultists, and evil armies. Lead a band of heroes after bandits attack your village.",
		config = GENERIC_CONFIG,
		battle_config = function(config)
			local permadeath = config.deaths ~= "casual"

			return {
				permadeath = permadeath,
			}
		end,
		nodes = {
			save_auto = {
				campaigns.save_game(),
				campaigns.story_text("Progress saved."),
			},
			save_ask = {
				campaigns.select_option({
					{ id = "save", name = "Save", description = "Save your progress." },
					{ id = "skip", name = "Don't Save", description = "Continue without saving." },
				}, "save_choice"),
				lib.libs.story.memory_branch(
					function(c, s) return s["save_choice"] == "save" end,
					campaigns.detour("save_auto"),
					campaigns.advance()
				),
			},
			prologue = {
				campaigns.chapter_header("Prologue"),
				campaigns.text_input("This is the story of ${hero_name}", "hero_name"),
				campaigns.set_memory("hero_village", "Herovillageton"),
				campaigns.character_customizer("hero", "hero_name"),
				campaigns.jump('ch_1_intro'),
			},
			ch_1_intro = {
				campaigns.new_page(),
				campaigns.chapter_header("Homecoming", 1),

				campaigns.story_text("After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
				campaigns.story_text("From the distance, songs of battle could be heard.  There could be no mistake, these were bandits!"),
				campaigns.story_text("${hero_village} held no militia of its own, so ${hero.name} would need to face the bandit threat alone."),
				campaigns.story_text("Prepare for battle!"),

				campaigns.battle('bandit_village', 'ch_1_v', 'ch_1_f'),
			},
			ch_1_v = {
				campaigns.new_page(),
				lib.libs.story.config_branch(function(c) return c.deaths == "classic" end, campaigns.story_text("${stats.current.players_lost} of your units fell in combat."), campaigns.advance()),
				lib.libs.story.config_branch(function(c) return c.saving == "ask" end, campaigns.detour("save_ask"), campaigns.detour("save_auto")),
				campaigns.new_page(),
				campaigns.story_text("After defeating the bandits' leader, ${hero.name} and their newfound allies forced the bandit forces to retreat from ${hero_village}."),
				campaigns.story_text("The party would proceed to the capitol, to petition for aid in defending against the bandit threat."),
				campaigns.jump('ch_2_intro'),
			},
			ch_1_f = {
				campaigns.new_page(),
				campaigns.story_text("${hero.name} and the visiting militia were no match for the bandits."),
				campaigns.story_text("${hero_village} would find itself under bandit rule for years to come."),
				campaigns.jump('game_over'),
			},
			ch_2_intro = {
				campaigns.save_game(),
				campaigns.new_page(),
				campaigns.chapter_header("Those Who Act in the Shadows", 2),

				campaigns.story_text("En route to the capitol, ${hero.name}'s party learned of a local cult."),
				campaigns.story_text("The cult kept a hideout in a nearby cave, where they would hold prisoners for sacrifice."),
				campaigns.story_text("Though the leader is powerful, the party could attempt to free some prisoners before making an escape."),
				campaigns.story_text("Prepare for battle!"),

				campaigns.battle('cultist_cave', 'ch_2_v', 'ch_2_f'),
			},
			ch_2_v = {
				campaigns.new_page(),
				lib.libs.story.config_branch(function(c) return c.deaths == "classic" end, campaigns.story_text("${stats.current.players_lost} of your units fell in combat."), campaigns.advance()),
				lib.libs.story.config_branch(function(c) return c.saving == "ask" end, campaigns.detour("save_ask"), campaigns.detour("save_auto")),
				campaigns.new_page(),
				campaigns.story_text("The heroes managed to escape the cave."),
				campaigns.story_text("Future encounters may not afford such stealthy encounters."),
				campaigns.jump('ch_3_intro'),
			},
			ch_2_f = {
				campaigns.new_page(),
				campaigns.story_text("Defeat!"),
				campaigns.jump('game_over'),
			},
			ch_3_intro = {
				campaigns.save_game(),
				campaigns.new_page(),
				campaigns.chapter_header("", 3),

				campaigns.story_text("As their journey continued, the party reached a fortress town, a final bastion of safety before they could cross bandit-infested cliffs to reach the capitol."),
				campaigns.story_text("There would be no time for rest, however.  Bandits were laying siege to the fortress."),
				campaigns.story_text("It made no sense.  The fortress was well guarded."),
				campaigns.story_text("Why wouldn't the army put up a fight?"),
				campaigns.story_text("Prepare for battle!"),

				campaigns.battle('fortress_town', 'ch_3_v', 'ch_3_f'),
			},
			ch_3_v = {
				campaigns.new_page(),
				lib.libs.story.config_branch(function(c) return c.deaths == "classic" end, campaigns.story_text("${stats.current.players_lost} of your units fell in combat."), campaigns.advance()),
				lib.libs.story.config_branch(function(c) return c.saving == "ask" end, campaigns.detour("save_ask"), campaigns.detour("save_auto")),
				campaigns.new_page(),

				campaigns.story_text("Clearly, bandit influence ran deep here."),
				campaigns.story_text("${hero.name} would need to keep their guard up as they proceeded through the cliffs."),

				campaigns.jump('ch_4_intro'),
			},
			ch_3_f = {
				campaigns.new_page(),
				campaigns.story_text("Defeat!"),
				campaigns.jump('game_over'),
			},
			ch_4_intro = {
				campaigns.save_game(),
				campaigns.new_page(),
				campaigns.chapter_header("Unlikely Alliance", 4),

				campaigns.story_text("${hero.name} was prepared for bandits when they approached the cliffs."),
				campaigns.story_text("To their surprise, though, the bandits were not alone this time."),
				campaigns.story_text("Cultists should hate bandits!  Why were they working together?"),

				campaigns.story_text("Prepare for battle!"),
				campaigns.story_text("And watch for rolling rocks!"),

				campaigns.battle('cliff_crossing', 'ch_4_v', 'ch_4_f'),
			},
			ch_4_v = {
				campaigns.new_page(),
				lib.libs.story.config_branch(function(c) return c.deaths == "classic" end, campaigns.story_text("${stats.current.players_lost} of your units fell in combat."), campaigns.advance()),
				lib.libs.story.config_branch(function(c) return c.saving == "ask" end, campaigns.detour("save_ask"), campaigns.detour("save_auto")),
				campaigns.new_page(),

				campaigns.story_text("Clearly, bandit influence ran deep here."),
				campaigns.story_text("${hero.name} would need to keep their guard up as they proceeded through the cliffs."),

				campaigns.jump('ch_5_intro'),
			},
			ch_4_f = {
				campaigns.new_page(),
				campaigns.story_text("Defeat!"),
				campaigns.jump('game_over'),
			},
			ch_5_intro = {
				campaigns.save_game(),
				campaigns.new_page(),
				campaigns.chapter_header("Last Stand", 5),

				campaigns.story_text("At last, ${hero.name} had reached the capitol.  And just in the nick of time."),
				campaigns.story_text("A three-pronged alliance of bandits, cultists, and defecting milita were assaulting the fortress."),

				campaigns.story_text("This is it, the final battle!  Protect the monarch!"),
				campaigns.story_text("Prepare for battle!"),

				campaigns.battle('castle_defense', 'ch_5_v', 'ch_5_f'),
			},
			ch_5_v = {
				campaigns.new_page(),
				lib.libs.story.config_branch(function(c) return c.deaths == "classic" end, campaigns.story_text("${stats.current.players_lost} of your units fell in combat."), campaigns.advance()),
				lib.libs.story.config_branch(function(c) return c.saving == "ask" end, campaigns.detour("save_ask"), campaigns.detour("save_auto")),
				campaigns.new_page(),

				campaigns.jump('victory'),
			},
			ch_5_f = {
				campaigns.new_page(),
				campaigns.story_text("Defeat!"),
				campaigns.jump('game_over'),
			},
			victory = {
				campaigns.save_game(),
				campaigns.new_page(),
				campaigns.chapter_header("Victory"),
				campaigns.story_text("Congratulations!"),
				campaigns.story_text("Thank you so much for playing my game.  Please share any feedback you have.  I'm excited to improve the systems and add new content."),
				campaigns.exit_campaign(),
			},
			game_over = {
				campaigns.new_page(),
				campaigns.chapter_header("Game Over"),
				campaigns.story_text("Try again.  I believe in you!"),
				lib.libs.story.config_branch(
					function(c) return c.saving == "hardcore" end,
					campaigns.jump("delete_file"),
					campaigns.advance()
				),
				campaigns.exit_campaign(),
			},
			delete_file = {
				campaigns.delete_file(),
				campaigns.story_text("File deleted."),
				campaigns.exit_campaign(),
			}
		}
	}
}


---@type ModStoriesModule
local stories_mod = {
	data = STORIES,
}

return stories_mod
