local luassert = require("luassert")

local Campaign = require("src.tactics.campaign.campaign").Campaign
local HANDLERS  = require("src.tactics.campaign.handlers.node_handlers")

-- ---------------------------------------------------------------------------
-- Test helper: minimal Campaign-like object
-- ---------------------------------------------------------------------------

--- Build a partial Campaign that can run advance_node / jump_to_node_step
--- without any real services.  handle_new_node records each visit and
--- auto-advances only the logic-only nodes (advance, detour) so chains
--- terminate without needing full service stubs.
---@param nodes table<string, table>
---@return table campaign, table visited
local function make_campaign(nodes)
    local visited = {}
    local self = setmetatable({
        campaign_definition = { nodes = nodes },
        campaign_config     = {},
        rng_context         = {},
        return_stack        = {},
        current_node        = {},
    }, { __index = Campaign })

    self.handle_new_node = function(camp)
        local node = camp.current_node.definition
        table.insert(visited, {
            node_id   = camp.current_node.node_id,
            node_step = camp.current_node.node_step,
            type      = node.type,
        })
        -- auto-advance only nodes that don't require services
        if node.type == "advance" or node.type == "detour" then
            local h = HANDLERS[node.type]
            if h then h.enter(camp, node) end
        end
    end

    return self, visited
end

-- ---------------------------------------------------------------------------
-- Handler unit tests
-- ---------------------------------------------------------------------------

describe("detour handler", function()
    it("pushes the correct return point onto return_stack", function()
        local mock = {
            current_node = { node_id = "main", node_step = 3, definition = nil },
            return_stack = {},
            jump_to_node = function() end,
        }
        HANDLERS.detour.enter(mock, { type = "detour", target = "sub" })

        luassert.are_equal(1, #mock.return_stack)
        luassert.are_equal("main", mock.return_stack[1].node_id)
        luassert.are_equal(4, mock.return_stack[1].node_step)  -- node_step + 1
    end)

    it("jumps to the target node", function()
        local jumped_to = nil
        local mock = {
            current_node = { node_id = "main", node_step = 1, definition = nil },
            return_stack = {},
            jump_to_node = function(_, target) jumped_to = target end,
        }
        HANDLERS.detour.enter(mock, { type = "detour", target = "sub" })

        luassert.are_equal("sub", jumped_to)
    end)
end)

-- ---------------------------------------------------------------------------
-- advance_node return-stack integration
-- ---------------------------------------------------------------------------

describe("Campaign:advance_node detour return", function()
    it("resumes at the caller step when the detoured node is exhausted", function()
        -- main: detour(sub) → step2 (terminal)
        -- sub:  advance  (1 step; exhaustion triggers return to main/2)
        local self, _ = make_campaign({
            main = {
                { type = "detour", target = "sub" },  -- step 1
                { type = "text",   text  = "back" },  -- step 2 — resume target
            },
            sub = {
                { type = "advance" },                 -- sole step; exhaustion returns
            },
        })

        Campaign.jump_to_node(self, "main")

        -- Should have returned to main/2 without further auto-advance
        luassert.are_equal("main", self.current_node.node_id)
        luassert.are_equal(2,      self.current_node.node_step)
        luassert.are_equal("text", self.current_node.definition.type)
        luassert.are_equal(0,      #self.return_stack)
    end)

    it("does not pop return_stack when remaining steps exist", function()
        local self, _ = make_campaign({
            main = {
                { type = "advance" },
                { type = "text", text = "b" },
            },
        })
        self.return_stack = { { node_id = "caller", node_step = 99 } }
        self.current_node = {
            node_id    = "main",
            node_step  = 1,
            definition = { type = "advance" },
        }

        -- advance from step 1 → step 2; step 2 exists, so return_stack stays
        Campaign.advance_node(self)

        luassert.are_equal("main", self.current_node.node_id)
        luassert.are_equal(2,      self.current_node.node_step)
        luassert.are_equal(1,      #self.return_stack)
    end)
end)

-- ---------------------------------------------------------------------------
-- Nested detours
-- ---------------------------------------------------------------------------

describe("nested detours", function()
    it("preserves the outer return point across an inner detour", function()
        -- main  → detour(mid)   → resume main/2 (text)
        -- mid   → detour(inner) → resume mid/2  (advance → exhausted → return to main/2)
        -- inner → advance       → exhausted → return to mid/2
        local self, _ = make_campaign({
            main = {
                { type = "detour", target = "mid" },   -- step 1
                { type = "text",   text = "main end" }, -- step 2
            },
            mid = {
                { type = "detour", target = "inner" }, -- step 1
                { type = "advance" },                  -- step 2 (return from inner)
            },
            inner = {
                { type = "advance" },                  -- sole step
            },
        })

        Campaign.jump_to_node(self, "main")

        luassert.are_equal("main", self.current_node.node_id)
        luassert.are_equal(2,      self.current_node.node_step)
        luassert.are_equal("text", self.current_node.definition.type)
        luassert.are_equal(0,      #self.return_stack)
    end)
end)

-- ---------------------------------------------------------------------------
-- story.detour helper (base/lib/story)
-- ---------------------------------------------------------------------------

describe("story.detour helper", function()
    local story = require("base.lib.story").story

    it("returns a node with type 'detour'", function()
        local node = story.detour("some_node")
        luassert.are_equal("detour", node.type)
    end)

    it("sets the target field", function()
        local node = story.detour("some_node")
        luassert.are_equal("some_node", node.target)
    end)
end)
