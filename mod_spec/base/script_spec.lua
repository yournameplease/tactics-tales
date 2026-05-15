require("src.spec.picotron_shim")
local luassert  = require("luassert")
local script_lib = require("base.lib.script")
local script     = script_lib.script

describe("base.lib.script", function()
    describe("ScriptBuilder:then_enable_units", function()
        it("produces a modify_units effect with enabled = true and the given selector", function()
            local s = script.on_turn(1, "before_player")
                :then_enable_units({ type = "tag_lookup", tag = "foo" })
            local effect = s.effects[1]
            luassert.are_equal("modify_units", effect.type)
            luassert.is_true(effect.enabled)
            luassert.are_same({ type = "tag_lookup", tag = "foo" }, effect.unit_selector)
        end)
    end)
end)
