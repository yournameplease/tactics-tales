local c = lib.libs.campaign

local GENERIC_CONFIG = {
    options = {
        {
            key = "turn_difficulty",
            name = "Turn difficulty",
            description =
            "How much time you are given to complete chapters. Exceeding the turn limit will result in a failure.",
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
                -- TODO: we should change the flow to better handle this...
                -- Maybe just add an ability to save and quit at any time.
                -- {
                -- 	name = "Normal",
                -- 	value = "ask",
                -- 	description = "After each victory, choose whether to save.",
                -- },
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
            values = { turn_difficulty = "easy", saving = "ironman", deaths = "casual" },
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
    bandit_village = c.chapter_debug(
        {},
        "Chapter 1: Bandit Village",
        "A young hero finds their village under attack by bandits!",
        "bandit_village"
    ),
    cultist_cave = c.chapter_debug(
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
    fortress_town = c.chapter_debug(
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
    cliff_crossing = c.chapter_debug(
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
    castle_defense = c.chapter_debug(
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
    demo_playground = c.chapter_debug(
        {},
        "Playground",
        "Various characters to assist in debugging.",
        "playground"
    ),
    model_room = c.chapter_debug(
        {},
        "Model Room",
        "A lot of randomly generated characters.",
        "model_room"
    ),
    convention_demo = {
        starting_node = 'prologue',
        name = 'Tactics Tales Fantasy',
        description =
        "A simple story of bandits, cultists, and evil armies. Lead a band of heroes after bandits attack your village.",
        config = GENERIC_CONFIG,
        battle_config = c.static_battle_config { permadeath = true },
        nodes = {
            prologue = {
                c.chapter_header("Tactics Tales"),
                c.text_input("This is the story of ${hero_name}", "hero_name"),
                c.set_state("hero_village", "Herovillageton"),
                c.character_customizer("hero", "hero_name"),
                c.jump('ch_1_intro'),
            },
            ch_1_intro = {
                c.new_page(),

                c.text(
                "After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
                c.text(
                "From the distance, songs of battle could be heard.  There could be no mistake, these were bandits!"),
                c.text(
                "${hero_village} had a sole militiaman, so ${hero.name} would need to help with the bandit threat."),
                c.text("Prepare for battle!"),

                c.start_battle('bandit_village', { victory = 'ch_1_v', failure = 'ch_1_f' }),
            },
            ch_1_v = {
                c.new_page(),
                c.text(
                "After defeating the bandits' leader, ${hero.name} and their newfound allies forced the bandit forces to retreat from ${hero_village}."),
                c.text(
                "The party would proceed to the capitol, to petition for aid in defending against the bandit threat."),
                c.text("But you'll need to play the full game to see that!"),
                c.text("Check it out at \nyour-name-please.itch.io/tactics-tales!"),
                c.exit_campaign(),
            },
            ch_1_f = {
                c.new_page(),
                c.text("${hero.name} and the visiting militia were no match for the bandits."),
                c.text("${hero_village} would find itself under bandit rule for years to come."),
                c.text("Try again for a victory. I believe in you!"),
                c.text("Or, play the full game at \nyour-name-please.itch.io/tactics-tales!"),
                c.exit_campaign(),
            },
        },
    },
    demo_campaign = {
        starting_node = 'prologue',
        name = 'Tactics Tales Fantasy',
        description =
        "A simple campaign of bandits, cultists, and evil armies. Lead a band of heroes after bandits attack your village.",
        config = GENERIC_CONFIG,
        battle_config = function(config)
            local permadeath = config.deaths ~= "casual"

            return {
                permadeath = permadeath,
            }
        end,
        nodes = {
            save_auto = {
                c.save_game()
            },
            save_ask = {
                c.select_option({
                    { id = "save", name = "Save",       description = "Save your progress." },
                    { id = "skip", name = "Don't Save", description = "Continue without saving." },
                }, "save_choice"),
                c.state_branch(
                    function(cfg, s) return s["save_choice"] == "save" end,
                    c.detour("save_auto"),
                    c.advance()
                ),
            },
            prologue = {
                c.chapter_header("Prologue"),
                c.text_input("This is the story of ${hero_name}", "hero_name"),
                c.set_state("hero_village", "Herovillageton"),
                c.character_customizer("hero", "hero_name"),
                c.jump('ch_1_intro'),
            },
            ch_1_intro = {
                c.new_page(),
                c.chapter_header("Homecoming", 1),

                c.text(
                "After many months away training to join the royal army, ${hero.name} returned home. However, this would be no peaceful reunion."),
                c.text(
                "From the distance, songs of battle could be heard.  There could be no mistake, these were bandits!"),
                c.text(
                "${hero_village} held no militia of its own, so ${hero.name} would need to face the bandit threat alone."),
                c.text("Prepare for battle!"),

                c.start_battle('bandit_village', { victory = 'ch_1_v', failure = 'ch_1_f' }),
            },
            ch_1_v = {
                c.new_page(),
                c.config_branch(function(cfg) return cfg.deaths == "classic" end,
                    c.text("${stats.current.players_lost} of your units fell in combat."), c.advance()),
                c.config_branch(function(cfg) return cfg.saving == "ask" end, c.detour("save_ask"), c.detour("save_auto")),
                c.new_page(),
                c.text(
                "After defeating the bandits' leader, ${hero.name} and their newfound allies forced the bandit forces to retreat from ${hero_village}."),
                c.text(
                "The party would proceed to the capitol, to petition for aid in defending against the bandit threat."),
                c.jump('ch_2_intro'),
            },
            ch_1_f = {
                c.new_page(),
                c.text("${hero.name} and the visiting militia were no match for the bandits."),
                c.text("${hero_village} would find itself under bandit rule for years to come."),
                c.jump('game_over'),
            },
            ch_2_intro = {
                c.save_game(),
                c.new_page(),
                c.chapter_header("Those Who Act in the Shadows", 2),

                c.text("En route to the capitol, ${hero.name}'s party learned of a local cult."),
                c.text("The cult kept a hideout in a nearby cave, where they would hold prisoners for sacrifice."),
                c.text(
                "Though the leader is powerful, the party could attempt to free some prisoners before making an escape."),
                c.text("Prepare for battle!"),

                c.start_battle('cultist_cave', { victory = 'ch_2_v', failure = 'ch_2_f' }),
            },
            ch_2_v = {
                c.new_page(),
                c.config_branch(function(cfg) return cfg.deaths == "classic" end,
                    c.text("${stats.current.players_lost} of your units fell in combat."), c.advance()),
                c.config_branch(function(cfg) return cfg.saving == "ask" end, c.detour("save_ask"), c.detour("save_auto")),
                c.new_page(),
                c.text("The heroes managed to escape the cave."),
                c.text("Future encounters may not afford such stealthy encounters."),
                c.jump('ch_3_intro'),
            },
            ch_2_f = {
                c.new_page(),
                c.text("Defeat!"),
                c.jump('game_over'),
            },
            ch_3_intro = {
                c.save_game(),
                c.new_page(),
                c.chapter_header("", 3),

                c.text(
                "As their journey continued, the party reached a fortress town, a final bastion of safety before they could cross bandit-infested cliffs to reach the capitol."),
                c.text("There would be no time for rest, however.  Bandits were laying siege to the fortress."),
                c.text("It made no sense.  The fortress was well guarded."),
                c.text("Why wouldn't the army put up a fight?"),
                c.text("Prepare for battle!"),

                c.start_battle('fortress_town', { victory = 'ch_3_v', failure = 'ch_3_f' }),
            },
            ch_3_v = {
                c.new_page(),
                c.config_branch(function(cfg) return cfg.deaths == "classic" end,
                    c.text("${stats.current.players_lost} of your units fell in combat."), c.advance()),
                c.config_branch(function(cfg) return cfg.saving == "ask" end, c.detour("save_ask"), c.detour("save_auto")),
                c.new_page(),

                c.text("Clearly, bandit influence ran deep here."),
                c.text("${hero.name} would need to keep their guard up as they proceeded through the cliffs."),

                c.jump('ch_4_intro'),
            },
            ch_3_f = {
                c.new_page(),
                c.text("Defeat!"),
                c.jump('game_over'),
            },
            ch_4_intro = {
                c.save_game(),
                c.new_page(),
                c.chapter_header("Unlikely Alliance", 4),

                c.text("${hero.name} was prepared for bandits when they approached the cliffs."),
                c.text("To their surprise, though, the bandits were not alone this time."),
                c.text("Cultists should hate bandits!  Why were they working together?"),

                c.text("Prepare for battle!"),
                c.text("And watch for rolling rocks!"),

                c.start_battle('cliff_crossing', { victory = 'ch_4_v', failure = 'ch_4_f' }),
            },
            ch_4_v = {
                c.new_page(),
                c.config_branch(function(cfg) return cfg.deaths == "classic" end,
                    c.text("${stats.current.players_lost} of your units fell in combat."), c.advance()),
                c.config_branch(function(cfg) return cfg.saving == "ask" end, c.detour("save_ask"), c.detour("save_auto")),
                c.new_page(),

                c.text("Clearly, bandit influence ran deep here."),
                c.text("${hero.name} would need to keep their guard up as they proceeded through the cliffs."),

                c.jump('ch_5_intro'),
            },
            ch_4_f = {
                c.new_page(),
                c.text("Defeat!"),
                c.jump('game_over'),
            },
            ch_5_intro = {
                c.save_game(),
                c.new_page(),
                c.chapter_header("Last Stand", 5),

                c.text("At last, ${hero.name} had reached the capitol.  And just in the nick of time."),
                c.text(
                "A three-pronged alliance of bandits, cultists, and defecting milita were assaulting the fortress."),

                c.text("This is it, the final battle!  Protect the monarch!"),
                c.text("Prepare for battle!"),

                c.start_battle('castle_defense', { victory = 'ch_5_v', failure = 'ch_5_f' }),
            },
            ch_5_v = {
                c.new_page(),
                c.config_branch(function(cfg) return cfg.deaths == "classic" end,
                    c.text("${stats.current.players_lost} of your units fell in combat."), c.advance()),
                c.config_branch(function(cfg) return cfg.saving == "ask" end, c.detour("save_ask"), c.detour("save_auto")),
                c.new_page(),

                c.jump('victory'),
            },
            ch_5_f = {
                c.new_page(),
                c.text("Defeat!"),
                c.jump('game_over'),
            },
            victory = {
                c.save_game(),
                c.new_page(),
                c.chapter_header("Victory"),
                c.text("Congratulations!"),
                c.text(
                "Thank you so much for playing my game.  Please share any feedback you have.  I'm excited to improve the systems and add new content."),
                c.exit_campaign(),
            },
            game_over = {
                c.new_page(),
                c.chapter_header("Game Over"),
                c.text("Try again.  I believe in you!"),
                c.config_branch(
                    function(cfg) return cfg.saving == "hardcore" end,
                    c.jump("delete_file"),
                    c.advance()
                ),
                c.exit_campaign(),
            },
            delete_file = {
                c.delete_file(),
                c.text("File deleted."),
                c.exit_campaign(),
            }
        }
    }
}


---@type ModStoriesModule
local stories_mod = {
    data = STORIES,
}

return stories_mod
