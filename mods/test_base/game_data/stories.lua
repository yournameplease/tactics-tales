---@type ModStoriesModule
local stories = {
    data = {
        -- Completes immediately on start. Baseline smoke test.
        simple_exit = {
            starting_node = "exit",
            nodes = {
                exit = {
                    { type = "exit_story" },
                },
            },
        },

        -- Two text nodes then exit. Tests that confirm() advances through sequential text.
        linear_text = {
            starting_node = "main",
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

        -- Advance node then exit. Tests that advance completes without any confirm().
        advance_and_exit = {
            starting_node = "main",
            nodes = {
                main = {
                    { type = "advance" },
                    { type = "exit_story" },
                },
            },
        },

        -- Battle node then exit. Tests the story↔battle boundary.
        -- Uses rout_no_enemies: VICTORY on first finish_player_turn().
        battle_and_exit = {
            starting_node = "the_battle",
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
    default_story = "simple_exit",
    story_select  = { "simple_exit", "linear_text", "jump_flow" },
}

return stories
