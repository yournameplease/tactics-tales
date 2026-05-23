local luassert = require("luassert")
local ui_context_stack = require("src.tactics.ui.ui_context_stack")

--- Build a stub UIContext with the given type/layout. Counts enrich calls.
---@param ctx_type string
---@param layout string
local function make_ctx(ctx_type, layout)
    return {
        type = ctx_type,
        layout = layout,
        enrich_count = 0,
        enrich = function(self) self.enrich_count = self.enrich_count + 1 end,
    }
end

describe("UIContextStack", function()
    it("uses the default layout when nothing is registered", function()
        local stack = ui_context_stack.new({ default_layout = "MENU" })
        stack:enrich()
        luassert.are_equal("MENU", stack.layout)
    end)

    it("registers a context by its type and exposes a typed mirror field", function()
        local stack = ui_context_stack.new()
        local ctx = make_ctx("overworld", "OVERWORLD_MAP")
        stack:register_ui_context(ctx)
        luassert.are_equal(ctx, stack:get("overworld"))
        luassert.are_equal(ctx, stack.overworld_context)
    end)

    it("rejects double registration and double unregistration", function()
        local stack = ui_context_stack.new()
        local a = make_ctx("a", "A")
        stack:register_ui_context(a)
        luassert.has_error(function() stack:register_ui_context(a) end)
        stack:unregister_ui_context("a")
        luassert.has_error(function() stack:unregister_ui_context("a") end)
    end)

    it("enriches every registered context once per enrich() call", function()
        local stack = ui_context_stack.new()
        local a = make_ctx("a", "A")
        local b = make_ctx("b", "B")
        stack:register_ui_context(a)
        stack:register_ui_context(b)
        stack:enrich()
        stack:enrich()
        luassert.are_equal(2, a.enrich_count)
        luassert.are_equal(2, b.enrich_count)
    end)

    it("selects layout from the first present context in layout_priority", function()
        -- Wire a totally different game shape: gameplay → pause_menu, with
        -- pause_menu winning when both are registered.
        local stack = ui_context_stack.new({
            layout_priority = { "pause_menu", "gameplay" },
            default_layout = "TITLE",
        })

        local gameplay = make_ctx("gameplay", "GAMEPLAY")
        stack:register_ui_context(gameplay)
        stack:enrich()
        luassert.are_equal("GAMEPLAY", stack.layout)

        local pause = make_ctx("pause_menu", "PAUSE")
        stack:register_ui_context(pause)
        stack:enrich()
        luassert.are_equal("PAUSE", stack.layout)

        stack:unregister_ui_context("pause_menu")
        stack:enrich()
        luassert.are_equal("GAMEPLAY", stack.layout)

        stack:unregister_ui_context("gameplay")
        stack:enrich()
        luassert.are_equal("TITLE", stack.layout)
    end)
end)
