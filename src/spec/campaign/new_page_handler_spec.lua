local luassert = require("luassert")

local HANDLERS = require("src.tactics.campaign.handlers.node_handlers")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@return table campaign, table spy
local function make_campaign_with_spy()
    local spy = { called = false, direction = nil, callback = nil }
    local campaign = {
        page_flip_animator = {
            begin_flip = function(_, direction, callback)
                spy.called = true
                spy.direction = direction
                spy.callback = callback
            end,
        },
        campaign_page = {
            clear_page = function(self) self.cleared = true end,
            cleared = false,
        },
        advance_node = function(self) self.advanced = true end,
        advanced = false,
    }
    return campaign, spy
end

---@type CampaignNode
local dummy_node = { type = "new_page" }

-- ---------------------------------------------------------------------------
-- new_page handler
-- ---------------------------------------------------------------------------

describe("new_page handler", function()
    describe("enter", function()
        it("calls begin_flip with direction 'forward'", function()
            local campaign, spy = make_campaign_with_spy()
            HANDLERS.new_page.enter(campaign, dummy_node)
            luassert.is_true(spy.called)
            luassert.are_equal("forward", spy.direction)
        end)

        it("does not immediately clear the page or advance the node", function()
            local campaign, _ = make_campaign_with_spy()
            HANDLERS.new_page.enter(campaign, dummy_node)
            luassert.is_false(campaign.campaign_page.cleared)
            luassert.is_false(campaign.advanced)
        end)

        it("callback clears the page", function()
            local campaign, spy = make_campaign_with_spy()
            HANDLERS.new_page.enter(campaign, dummy_node)
            spy.callback()
            luassert.is_true(campaign.campaign_page.cleared)
        end)

        it("callback advances the node", function()
            local campaign, spy = make_campaign_with_spy()
            HANDLERS.new_page.enter(campaign, dummy_node)
            spy.callback()
            luassert.is_true(campaign.advanced)
        end)
    end)
end)
