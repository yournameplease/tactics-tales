local luassert = require("luassert")

local recruitment_quota      = require("tt_procedural_story.game_data.recruitment_quota")
local update_recruitment_quota = recruitment_quota.update_recruitment_quota

local story_memory = require("src.tactics.story.story_memory")
local random       = require("src.tactics.util.random")

local function make_mem()
    return story_memory.new({ get_character = function() return nil end })
end

local function make_archetype(rate)
    return { recruitment_rate = rate }
end

describe("tt_procedural_story.recruitment_quota", function()
    describe("update_recruitment_quota", function()
        it("accumulates credits by recruitment_rate each call", function()
            local mem = make_mem()
            -- rate 0.5: after first call credits = 0.5, floor = 0, remainder = 0.5
            update_recruitment_quota(make_archetype(0.5), mem, random.new(1), "skirmish")
            local entry = mem:get("recruitment_quota_credits")
            ---@cast entry TextMemoryEntry
            luassert.are_equal("0.5", entry.text)
        end)

        it("carries fractional remainder forward across calls", function()
            local mem = make_mem()
            local rng = random.new(1)
            -- rate 0.5: call 1 => credits=0.5 remainder=0.5, call 2 => credits=1.0 floor=1 remainder=0
            update_recruitment_quota(make_archetype(0.5), mem, rng, "skirmish")
            update_recruitment_quota(make_archetype(0.5), mem, rng, "skirmish")
            local entry = mem:get("recruitment_quota_credits")
            ---@cast entry TextMemoryEntry
            luassert.are_equal("0.0", entry.text)
        end)

        it("floor(credits) recruits are rolled each call", function()
            local mem = make_mem()
            -- rate 2: first call => 2 recruits
            update_recruitment_quota(make_archetype(2), mem, random.new(1), "skirmish")
            local pending = mem:get("pending_recruits")
            ---@cast pending ListMemoryEntry
            luassert.are_equal(2, #pending.values)
        end)

        it("each recruit type is drawn from the template's recruitment_archetypes", function()
            local mem = make_mem()
            update_recruitment_quota(make_archetype(3), mem, random.new(1), "skirmish")
            local pending = mem:get("pending_recruits")
            ---@cast pending ListMemoryEntry
            for _, v in ipairs(pending.values) do
                -- skirmish only has "turncoat_enemy"
                luassert.are_equal("turncoat_enemy", v)
            end
        end)

        it("pending_recruits is empty when template is absent from battles_meta", function()
            local mem = make_mem()
            update_recruitment_quota(make_archetype(2), mem, random.new(1), "unknown_template")
            local pending = mem:get("pending_recruits")
            ---@cast pending ListMemoryEntry
            luassert.are_equal(0, #pending.values)
        end)

        it("writes pending_recruits as a list entry", function()
            local mem = make_mem()
            update_recruitment_quota(make_archetype(1), mem, random.new(1), "skirmish")
            local pending = mem:get("pending_recruits")
            luassert.is_not_nil(pending)
            luassert.are_equal("list", pending.type)
        end)

        it("writes recruitment_quota_credits as a text entry", function()
            local mem = make_mem()
            update_recruitment_quota(make_archetype(1), mem, random.new(1), "skirmish")
            local credits = mem:get("recruitment_quota_credits")
            luassert.is_not_nil(credits)
            luassert.are_equal("text", credits.type)
        end)

        it("returns a debug text line", function()
            local mem = make_mem()
            local text = update_recruitment_quota(make_archetype(2), mem, random.new(1), "skirmish")
            luassert.is_string(text)
            luassert.is_truthy(text:find("%[quota%]"))
        end)

        it("debug text includes recruit count and types", function()
            local mem = make_mem()
            local text = update_recruitment_quota(make_archetype(2), mem, random.new(1), "skirmish")
            luassert.is_truthy(text:find("2 recruit%(s%) pending"))
            luassert.is_truthy(text:find("turncoat_enemy"))
        end)

        it("debug text shows 'none' when no recruits rolled", function()
            local mem = make_mem()
            local text = update_recruitment_quota(make_archetype(0.4), mem, random.new(1), "skirmish")
            luassert.is_truthy(text:find("none"))
        end)
    end)
end)
