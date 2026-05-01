local luassert = require("luassert")

local stories_mod  = require("tt_procedural_story.game_data.stories")
local campaign_state = require("src.tactics.campaign.campaign_state")
local random       = require("src.tactics.util.random")

local proc_story = stories_mod.data.proc_story

local function make_mem()
    return campaign_state.new({ get_character = function() return nil end })
end

local function make_sc(mem)
    return { memory = mem }
end

local function make_rng_ctx(seed)
    return { story_rng = random.new(seed or 1) }
end

-- Call a step factory at the given index within the named node.
local function call_step(node_name, step_index, sc, rng_ctx)
    local node_steps = proc_story.nodes[node_name]
    local step = node_steps[step_index]
    if type(step) == "function" then
        return step(sc, rng_ctx or make_rng_ctx())
    end
    return step
end

describe("tt_procedural_story.stories proc_story", function()
    describe("node structure", function()
        it("has archetype_select node", function()
            luassert.is_not_nil(proc_story.nodes.archetype_select)
        end)

        it("has battle_loop node", function()
            luassert.is_not_nil(proc_story.nodes.battle_loop)
        end)

        it("has post_battle node", function()
            luassert.is_not_nil(proc_story.nodes.post_battle)
        end)

        it("archetype_select jumps to battle_loop", function()
            local nodes = proc_story.nodes.archetype_select
            local jump = nodes[#nodes]
            luassert.are_equal("jump", jump.type)
            luassert.are_equal("battle_loop", jump.next_node)
        end)

        it("archetype_select sets battle_index to 1", function()
            local nodes = proc_story.nodes.archetype_select
            local found = false
            for _, n in ipairs(nodes) do
                if n.type == "set_memory" and n.key == "battle_index" and n.value == "1" then
                    found = true
                end
            end
            luassert.is_true(found)
        end)

        it("battle_loop step 3 is a battle node for 'skirmish'", function()
            local step = proc_story.nodes.battle_loop[3]
            luassert.are_equal("battle", step.type)
            luassert.are_equal("skirmish", step.battle_id)
        end)

        it("battle victory routes to post_battle", function()
            local step = proc_story.nodes.battle_loop[3]
            luassert.are_equal("post_battle", step.next_node_victory)
        end)
    end)

    describe("battle_loop step 1 (update_recruitment_quota)", function()
        it("returns a text node", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("1"))
            local node = call_step("battle_loop", 1, make_sc(mem))
            luassert.are_equal("text", node.type)
        end)

        it("text contains [quota] prefix", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("1"))
            local node = call_step("battle_loop", 1, make_sc(mem))
            luassert.is_truthy(node.text:find("%[quota%]"))
        end)

        it("writes pending_recruits to memory", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("1"))
            call_step("battle_loop", 1, make_sc(mem))
            luassert.is_not_nil(mem:get("pending_recruits"))
        end)
    end)

    describe("battle_loop step 2 (select_faction)", function()
        it("returns a text node", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            local node = call_step("battle_loop", 2, make_sc(mem))
            luassert.are_equal("text", node.type)
        end)

        it("writes faction_id to memory", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            call_step("battle_loop", 2, make_sc(mem))
            local entry = mem:get("faction_id")
            luassert.is_not_nil(entry)
            luassert.are_equal("text", entry.type)
        end)
    end)

    describe("post_battle step 1 (forced_join)", function()
        it("returns roster_add for a slot with forced_join", function()
            local mem = make_mem()
            -- warband slot 1 (opening_skirmish) has forced_join = "bandit_goon"
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("1"))
            local node = call_step("post_battle", 1, make_sc(mem))
            luassert.are_equal("roster_add", node.type)
            luassert.are_equal("bandit_goon", node.template)
        end)

        it("returns advance for a slot without forced_join", function()
            local mem = make_mem()
            -- warband slot 2 is a plain filler with no forced_join
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("2"))
            local node = call_step("post_battle", 1, make_sc(mem))
            luassert.are_equal("advance", node.type)
        end)
    end)

    describe("post_battle step 2 (auto_recruit_pending)", function()
        it("returns a text node", function()
            local mem = make_mem()
            local node = call_step("post_battle", 2, make_sc(mem))
            luassert.are_equal("text", node.type)
        end)

        it("text contains [auto_recruit] prefix", function()
            local mem = make_mem()
            local node = call_step("post_battle", 2, make_sc(mem))
            luassert.is_truthy(node.text:find("%[auto_recruit%]"))
        end)
    end)

    describe("post_battle step 3 (increment and loop/exit)", function()
        it("increments battle_index", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("1"))
            call_step("post_battle", 3, make_sc(mem))
            local entry = mem:get("battle_index")
            ---@cast entry TextMemoryEntry
            luassert.are_equal("2", entry.text)
        end)

        it("returns jump node when more slots remain", function()
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("1"))
            local node = call_step("post_battle", 3, make_sc(mem))
            luassert.are_equal("jump", node.type)
            luassert.are_equal("battle_loop", node.next_node)
        end)

        it("returns exit_story when all slots are done", function()
            -- warband has 6 slots; battle_index=6 means the last slot just ran
            local mem = make_mem()
            mem:set("archetype_id", campaign_state.text("warband"))
            mem:set("battle_index", campaign_state.text("6"))
            local node = call_step("post_battle", 3, make_sc(mem))
            luassert.are_equal("exit_story", node.type)
        end)
    end)
end)
