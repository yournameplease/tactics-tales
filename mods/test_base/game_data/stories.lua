local function battle_config(params)
    return {
        permadeath = params.permadeath or true 
    }
end

---@type ModStoriesModule
local stories = {
    data = {
        -- Completes immediately on start. Baseline smoke test.
        simple_exit = {
            starting_node = "exit",
            battle_config = battle_config{},
            nodes = {
                exit = {
                    { type = "exit_story" },
                },
            },
        },

        -- Two text nodes then exit. Tests that confirm() advances through sequential text.
        linear_text = {
            starting_node = "main",
            battle_config = battle_config{},
            nodes = {
                main = {
                    { type = "text", text = "First line." },
                    { type = "text", text = "Second line." },
                    { type = "exit_story" },
                },
            },
        },

        -- Jump from start node to a named target. Tests jump routing.
        jump_flow = {
            starting_node = "start",
            battle_config = battle_config{},
            nodes = {
                start = {
                    { type = "jump", next_node = "jump_target" },
                },
                jump_target = {
                    { type = "text", text = "You jumped here." },
                    { type = "exit_story" },
                },
            },
        },

        -- Function node branches on config.show_text: text node if true, advance node otherwise.
        config_branch = {
            starting_node = "main",
            battle_config = battle_config{},
            nodes = {
                main = {
                    function(config)
                        if config.show_text then
                            return { type = "text", text = "Config text." }
                        else
                            return { type = "advance" }
                        end
                    end,
                    { type = "exit_story" },
                },
            },
        },

        -- Advance node then exit. Tests that advance completes without any confirm().
        advance_and_exit = {
            starting_node = "main",
            battle_config = battle_config{},
            nodes = {
                main = {
                    { type = "advance" },
                    { type = "exit_story" },
                },
            },
        },

        -- select_option node: shows two options, stores chosen ID in memory, then exits.
        option_select_and_exit = {
            starting_node = "main",
            battle_config = battle_config{},
            nodes = {
                main = {
                    { type = "select_option", memory_key = "chosen", options = {
                        { id = "warrior", name = "Warrior", description = "A melee fighter." },
                        { id = "mage", name = "Mage", description = "A magic user." },
                    }},
                    { type = "exit_story" },
                },
            },
        },

        -- delete_file node then exit. Tests that delete_file advances without a confirm().
        delete_file_and_exit = {
            starting_node = "main",
            battle_config = battle_config{},
            nodes = {
                main = {
                    { type = "delete_file" },
                    { type = "exit_story" },
                },
            },
        },

        -- Parameterised by story_config.permadeath. Enemy kills player on first finish_player_turn().
        -- permadeath=false: character stays in roster. permadeath=true: character removed from roster.
        close_combat = {
            starting_node = "the_battle",
            battle_config = function(story_config)
                return { permadeath = story_config.permadeath }
            end,
            nodes = {
                the_battle = {
                    { type = "battle", battle_id = "close_combat",
                      next_node_victory = "after",
                      next_node_failure = "after" },
                },
                after = {
                    { type = "exit_story" },
                },
            },
        },

        -- Battle node then exit. Tests the story↔battle boundary.
        -- Uses rout_no_enemies: VICTORY on first finish_player_turn().
        battle_and_exit = {
            starting_node = "the_battle",
            battle_config = battle_config{},
            nodes = {
                the_battle = {
                    { type = "battle", battle_id = "rout_no_enemies",
                      next_node_victory = "after_victory",
                      next_node_failure = "after_defeat" },
                },
                after_victory = {
                    { type = "exit_story" },
                },
                after_defeat = {
                    { type = "exit_story" },
                },
            },
        },
    },
}

return stories
