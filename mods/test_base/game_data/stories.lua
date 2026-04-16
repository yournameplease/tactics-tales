return {
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
    },
    default_story = "simple_exit",
    story_select  = { "simple_exit", "linear_text", "jump_flow" },
}
