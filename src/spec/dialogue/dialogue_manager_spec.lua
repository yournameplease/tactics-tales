local luassert = require("luassert")
local dialogue_manager = require("src.tactics.dialogue.dialogue_manager")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal InputContext with BUTTON_A pressed or not.
---@param button_a_pressed boolean
---@return InputContext
local function make_input(button_a_pressed)
    return {
        actions = {
            BUTTON_A = { pressed = button_a_pressed }
        }
    }
end

--- Build DialogueProps with instant speed.
---@param overrides table?
---@return DialogueProps
local function instant_props(overrides)
    overrides = overrides or {}
    return {
        auto_advance = overrides.auto_advance or false,
        speed        = overrides.speed or "instant",
        can_skip     = overrides.can_skip or false,
    }
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.dialogue.dialogue_manager", function()
    ---@type DialogueManager
    local dm

    before_each(function()
        dm = dialogue_manager.new()
    end)

    describe("create_dialogue", function()
        it("should create a dialogue with correct initial state", function()
            local d = dm:create_dialogue({ "hello world" }, instant_props(), {})

            luassert.are_equal(1, d.current_row)
            luassert.are_equal(0, d.characters_rendered)
            luassert.is_falsy(d.finished)
        end)

        it("should replace ${var} placeholders in text at creation time", function()
            local d = dm:create_dialogue(
                { "hello ${name}, you have ${count} messages" },
                instant_props(),
                { name = "Alice", count = "3" }
            )

            luassert.are_equal("hello Alice, you have 3 messages", d.text[1])
        end)

        it("should substitute missing keys with [MISSING KEY: key]", function()
            local d = dm:create_dialogue(
                { "hi ${missing_var}" },
                instant_props(),
                {}
            )

            luassert.are_equal("hi [MISSING KEY: missing_var]", d.text[1])
        end)

        it("should return dynamically evaluated text when dynamic_replacement is true", function()
            local vars = { name = "alice" }
            local d = dm:create_dialogue(
                { "hi ${name}" },
                instant_props(),
                vars,
                true
            )

            luassert.are_equal("hi alice", d.text[1])

            vars.name = "bob"
            luassert.are_equal("hi bob", d.text[1])
        end)

        it("should substitute missing dynamic keys with underscores", function()
            local d = dm:create_dialogue(
                { "${unknown}" },
                instant_props(),
                {},
                true
            )

            luassert.are_equal("_____", d.text[1])
        end)

        it("should compute timer_limit as SPEED_MASK[speed] + 1 for slow speeds", function()
            local d = dm:create_dialogue({ "hi" }, instant_props({ speed = "normal" }), {})

            -- SPEED_MASK["normal"] = 0x01, so timer_limit = 2
            luassert.are_equal(2, d.timer_limit)
        end)
    end)

    describe("update", function()
        it("should fully render a row in one frame at instant speed", function()
            local d = dm:create_dialogue({ "hi" }, instant_props(), {})

            dm:update(make_input(false))

            luassert.is_true(d.characters_rendered >= #"hi")
        end)

        it("should advance to the next row when fully rendered and BUTTON_A is pressed", function()
            local d = dm:create_dialogue({ "hi", "bye" }, instant_props(), {})

            dm:update(make_input(false))  -- renders "hi" fully (9999 chars, >= 2)
            dm:update(make_input(true))   -- BUTTON_A pressed

            luassert.are_equal(2, d.current_row)
            luassert.are_equal(0, d.characters_rendered)
            luassert.is_falsy(d.finished)
        end)

        it("should set finished after advancing past the last row", function()
            local d = dm:create_dialogue({ "hi" }, instant_props(), {})

            dm:update(make_input(false))  -- renders fully
            dm:update(make_input(true))   -- BUTTON_A advances past last row

            luassert.is_true(d.finished)
        end)

        it("should auto-advance without BUTTON_A when auto_advance is true", function()
            local d = dm:create_dialogue(
                { "hi" },
                instant_props({ auto_advance = true }),
                {}
            )

            dm:update(make_input(false))  -- renders + auto-advances past last row

            luassert.is_true(d.finished)
        end)

        it("should skip to end of current row when can_skip and BUTTON_A is pressed", function()
            -- very_slow: first char renders only when (global_timer & 7) == 0.
            -- After the first update, global_timer=1, timer=(1&7)=1 != 0, so no chars rendered.
            -- The can_skip branch fires instead.
            local d = dm:create_dialogue(
                { "hello world" },
                instant_props({ speed = "very_slow", can_skip = true }),
                {}
            )

            dm:update(make_input(true))

            luassert.are_equal(#"hello world", d.characters_rendered)
        end)

        it("should not advance row when BUTTON_A is not pressed and auto_advance is false", function()
            local d = dm:create_dialogue({ "hi", "bye" }, instant_props(), {})

            dm:update(make_input(false))  -- renders fully
            dm:update(make_input(false))  -- no button press

            luassert.are_equal(1, d.current_row)
        end)

        it("should update multiple active dialogues independently", function()
            local d1 = dm:create_dialogue({ "hi" }, instant_props(), {})
            local d2 = dm:create_dialogue({ "bye" }, instant_props(), {})

            dm:update(make_input(false))

            luassert.is_true(d1.characters_rendered >= #"hi")
            luassert.is_true(d2.characters_rendered >= #"bye")
        end)
    end)
end)
