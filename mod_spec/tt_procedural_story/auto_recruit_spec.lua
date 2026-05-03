local luassert = require("luassert")

local auto_recruit       = require("tt_procedural_campaign.game_data.auto_recruit")
local auto_recruit_pending = auto_recruit.auto_recruit_pending

local campaign_state = require("src.tactics.campaign.campaign_state")

local function make_mem()
    return campaign_state.new({ get_character = function() return nil end })
end

describe("tt_procedural_campaign.auto_recruit", function()
    describe("auto_recruit_pending", function()
        it("clears pending_recruits in campaign memory", function()
            local mem = make_mem()
            mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy" }))
            auto_recruit_pending(mem)
            local entry = mem:get("pending_recruits")
            ---@cast entry ListMemoryEntry
            luassert.are_equal(0, #entry.values)
        end)

        it("writes an empty list entry (not nil) after clearing", function()
            local mem = make_mem()
            mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy" }))
            auto_recruit_pending(mem)
            local entry = mem:get("pending_recruits")
            luassert.is_not_nil(entry)
            luassert.are_equal("list", entry.type)
        end)

        it("returns a debug text line containing the pending types", function()
            local mem = make_mem()
            mem:set("pending_recruits", campaign_state.list({ "turncoat_enemy", "turncoat_enemy" }))
            local text = auto_recruit_pending(mem)
            luassert.is_truthy(text:find("%[auto_recruit%]"))
            luassert.is_truthy(text:find("turncoat_enemy"))
        end)

        it("debug text shows 'none' when pending list is empty", function()
            local mem = make_mem()
            mem:set("pending_recruits", campaign_state.list({}))
            local text = auto_recruit_pending(mem)
            luassert.is_truthy(text:find("none"))
        end)

        it("works when pending_recruits is absent from memory", function()
            local mem = make_mem()
            local text
            luassert.has_no_error(function()
                text = auto_recruit_pending(mem)
            end)
            luassert.is_truthy(text:find("none"))
        end)
    end)
end)
