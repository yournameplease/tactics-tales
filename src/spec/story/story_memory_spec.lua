local luassert = require("luassert")
local story_memory = require("src.tactics.story.story_memory")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal CharacterManager stub returning a single character.
---@param id integer
---@param name string
---@return CharacterManager
local function make_character_manager(id, name)
    return {
        get_character = function(_, char_id)
            if char_id == id then
                return { id = id, name = name }
            end
            return nil
        end,
    }
end

describe("tactics.story.story_memory", function()
    describe("text", function()
        it("should create an entry with type 'text'", function()
            local entry = story_memory.text("hello")
            luassert.are_equal("text", entry.type)
        end)

        it("should store the provided text", function()
            local entry = story_memory.text("hello")
            luassert.are_equal("hello", entry.text)
        end)
    end)

    describe("character", function()
        it("should create an entry with type 'character'", function()
            local entry = story_memory.character(42)
            luassert.are_equal("character", entry.type)
        end)

        it("should store the character_id", function()
            local entry = story_memory.character(42)
            ---@cast entry CharacterMemoryEntry
            luassert.are_equal(42, entry.character_id)
        end)

        it("should provide a placeholder text", function()
            local entry = story_memory.character(7)
            luassert.are_equal("[Character 7]", entry.text)
        end)
    end)

    describe("map", function()
        it("should create an entry with type 'map'", function()
            local entry = story_memory.map({ foo = "bar" })
            luassert.are_equal("map", entry.type)
        end)

        it("should store the entries table", function()
            local entry = story_memory.map({ foo = "bar", baz = "qux" })
            ---@cast entry MapMemoryEntry
            luassert.are_equal("bar", entry.entries.foo)
            luassert.are_equal("qux", entry.entries.baz)
        end)
    end)

    describe("set and get", function()
        it("should retrieve an entry that was set", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("hero", story_memory.text("Alice"))
            local entry = mem:get("hero")
            luassert.is_not_nil(entry)
            ---@cast entry StoryMemoryEntry
            luassert.are_equal("text", entry.type)
            luassert.are_equal("Alice", entry.text)
        end)

        it("should return nil for a key that was never set", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            luassert.is_nil(mem:get("missing"))
        end)

        it("should overwrite a previously set entry", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("key", story_memory.text("first"))
            mem:set("key", story_memory.text("second"))
            luassert.are_equal("second", mem:get("key").text)
        end)
    end)

    describe("get_as_map", function()
        it("should include text entries under their original key", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("greeting", story_memory.text("hello world"))
            local map = mem:get_as_map()
            luassert.are_equal("hello world", map["greeting"])
        end)

        it("should include character entries as '<key>.name'", function()
            local mem = story_memory.new(make_character_manager(5, "Bob"))
            mem:set("protagonist", story_memory.character(5))
            local map = mem:get_as_map()
            luassert.are_equal("Bob", map["protagonist.name"])
        end)

        it("should not include character entries under the bare key", function()
            local mem = story_memory.new(make_character_manager(5, "Bob"))
            mem:set("protagonist", story_memory.character(5))
            local map = mem:get_as_map()
            luassert.is_nil(map["protagonist"])
        end)

        it("should handle multiple entries of different types", function()
            local mem = story_memory.new(make_character_manager(3, "Carol"))
            mem:set("msg", story_memory.text("greetings"))
            mem:set("npc", story_memory.character(3))
            local map = mem:get_as_map()
            luassert.are_equal("greetings", map["msg"])
            luassert.are_equal("Carol", map["npc.name"])
        end)

        it("should error for an entry with an unknown type", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            -- Inject a bad entry directly to simulate corruption.
            ---@cast mem StoryMemoryImpl
            ---@diagnostic disable-next-line: assign-type-mismatch
            mem.global["bad"] = { type = "unknown", text = "?" }
            luassert.has_error(function()
                mem:get_as_map()
            end)
        end)

        it("should not include map entries in the output", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("counts", story_memory.map({ bandits = "2" }))
            local map = mem:get_as_map()
            luassert.is_nil(map["counts"])
        end)
    end)

    describe("serialize", function()
        it("should return a table containing all entries", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("a", story_memory.text("aaa"))
            mem:set("b", story_memory.character(1))
            local data = mem:serialize()
            luassert.are_equal("text", data["a"].type)
            luassert.are_equal("character", data["b"].type)
        end)

        it("should return an empty table when no entries exist", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            local data = mem:serialize()
            luassert.are_same({}, data)
        end)
    end)

    describe("deserialize", function()
        it("should load entries from a serialized table", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:deserialize({
                hero = story_memory.text("loaded"),
            })
            luassert.are_equal("loaded", mem:get("hero").text)
        end)

        it("should merge with existing entries", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("existing", story_memory.text("keep"))
            mem:deserialize({ new = story_memory.text("added") })
            luassert.are_equal("keep", mem:get("existing").text)
            luassert.are_equal("added", mem:get("new").text)
        end)

        it("should overwrite existing entries with the same key", function()
            local mem = story_memory.new(make_character_manager(1, "Alice"))
            mem:set("key", story_memory.text("old"))
            mem:deserialize({ key = story_memory.text("new") })
            luassert.are_equal("new", mem:get("key").text)
        end)

        it("should allow the deserialized data to round-trip through get_as_map", function()
            -- Arrange
            local mem1 = story_memory.new(make_character_manager(2, "Dave"))
            mem1:set("line", story_memory.text("from mem1"))
            local saved = mem1:serialize()

            -- Act
            local mem2 = story_memory.new(make_character_manager(2, "Dave"))
            mem2:deserialize(saved)
            local map = mem2:get_as_map()

            -- Assert
            luassert.are_equal("from mem1", map["line"])
        end)

        it("should round-trip a map entry through serialize and deserialize", function()
            local mem1 = story_memory.new(make_character_manager(1, "Alice"))
            mem1:set("counts", story_memory.map({ bandits = "2", cultists = "0" }))
            local saved = mem1:serialize()

            local mem2 = story_memory.new(make_character_manager(1, "Alice"))
            mem2:deserialize(saved)
            local entry = mem2:get("counts")
            luassert.is_not_nil(entry)
            ---@cast entry MapMemoryEntry
            luassert.are_equal("2", entry.entries.bandits)
            luassert.are_equal("0", entry.entries.cultists)
        end)
    end)
end)
