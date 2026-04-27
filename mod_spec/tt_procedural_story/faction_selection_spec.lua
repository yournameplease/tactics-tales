local luassert = require("luassert")

local faction_selection = require("tt_procedural_story.game_data.faction_selection")
local select_faction    = faction_selection.select_faction
local compute_weights   = faction_selection.compute_weights

local story_memory = require("src.tactics.story.story_memory")
local random       = require("src.tactics.util.random")

local function make_mem()
    return story_memory.new({ get_character = function() return nil end })
end

describe("tt_procedural_story.faction_selection", function()
    describe("compute_weights", function()
        it("prefer_novel: all factions at zero count yield base weights", function()
            local w = compute_weights({ bandits = 2, cultists = 1 }, {}, "prefer_novel")
            luassert.are_equal(2, w.bandits)
            luassert.are_equal(1, w.cultists)
        end)

        it("prefer_novel: higher-count faction gets lower adjusted weight", function()
            -- max=2; bandits: 1*(2-2+1)=1; cultists: 1*(2-0+1)=3
            local w = compute_weights(
                { bandits = 1, cultists = 1 },
                { bandits = 2, cultists = 0 },
                "prefer_novel"
            )
            luassert.are_equal(1, w.bandits)
            luassert.are_equal(3, w.cultists)
        end)

        it("prefer_dominant: all factions at zero count yield base weights", function()
            local w = compute_weights({ bandits = 2, cultists = 1 }, {}, "prefer_dominant")
            luassert.are_equal(2, w.bandits)
            luassert.are_equal(1, w.cultists)
        end)

        it("prefer_dominant: higher-count faction gets higher adjusted weight", function()
            -- bandits: 1*(2+1)=3; cultists: 1*(0+1)=1
            local w = compute_weights(
                { bandits = 1, cultists = 1 },
                { bandits = 2, cultists = 0 },
                "prefer_dominant"
            )
            luassert.are_equal(3, w.bandits)
            luassert.are_equal(1, w.cultists)
        end)
    end)

    describe("select_faction", function()
        it("returns a faction ID that exists in the pool", function()
            local archetype = { faction_pool = { bandits = 1, cultists = 1 }, bias = "prefer_novel" }
            local id = select_faction(archetype, make_mem(), random.new(1))
            luassert.is_not_nil(archetype.faction_pool[id])
        end)

        it("increments the count for the selected faction in memory", function()
            local archetype = { faction_pool = { bandits = 1 }, bias = "prefer_novel" }
            local mem = make_mem()
            select_faction(archetype, mem, random.new(1))
            local entry = mem:get("faction_appearance_counts")
            luassert.is_not_nil(entry)
            ---@cast entry MapMemoryEntry
            luassert.are_equal("1", entry.entries.bandits)
        end)

        it("accumulates counts across successive calls", function()
            local archetype = { faction_pool = { bandits = 1 }, bias = "prefer_novel" }
            local mem = make_mem()
            local rng = random.new(1)
            select_faction(archetype, mem, rng)
            select_faction(archetype, mem, rng)
            local entry = mem:get("faction_appearance_counts")
            ---@cast entry MapMemoryEntry
            luassert.are_equal("2", entry.entries.bandits)
        end)

        it("works when faction_appearance_counts is absent from memory", function()
            local archetype = { faction_pool = { bandits = 1 }, bias = "prefer_novel" }
            luassert.has_no_error(function()
                select_faction(archetype, make_mem(), random.new(1))
            end)
        end)
    end)
end)
