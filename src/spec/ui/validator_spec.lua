local luassert = require("luassert")

local validator = require("src.tactics.ui.validator")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@param opts? table
---@return table
local function make_element(opts)
    opts = opts or {}
    return {
        id = opts.id or "node",
        layout = {
            dir = opts.dir or "col",
            width = opts.width or 100,
            height = opts.height or 100,
        },
        children = opts.children or {},
    }
end

describe("tactics.ui.validator", function()
    describe("validate", function()
        it("should succeed for a node with no children", function()
            local node = make_element()
            validator.validate(node, "root")
        end)

        it("should succeed for a fit_content parent whose only fill child has a sibling", function()
            local child_fill = make_element({ id = "fill_child", height = "fill" })
            local child_fixed = make_element({ id = "fixed_child", height = 20 })
            local parent = make_element({ height = "fit_content", children = { child_fill, child_fixed } })
            validator.validate(parent, "root")
        end)

        it("should error when a fit_content height parent has only fill height children", function()
            local child = make_element({ id = "fill_child", height = "fill" })
            local parent = make_element({ height = "fit_content", children = { child } })
            luassert.has_error(function()
                validator.validate(parent, "root")
            end)
        end)

        it("should succeed for a fit_content width parent whose only fill child has a sibling", function()
            local child_fill = make_element({ id = "fill_child", width = "fill" })
            local child_fixed = make_element({ id = "fixed_child", width = 20 })
            local parent = make_element({ width = "fit_content", children = { child_fill, child_fixed } })
            validator.validate(parent, "root")
        end)

        it("should error when a fit_content width parent has only fill width children", function()
            local child = make_element({ id = "fill_child", width = "fill" })
            local parent = make_element({ width = "fit_content", children = { child } })
            luassert.has_error(function()
                validator.validate(parent, "root")
            end)
        end)

        it("should recurse and error on a deeply nested circular dependency", function()
            local grandchild = make_element({ id = "grandchild", height = "fill" })
            local middle = make_element({ id = "middle", height = "fit_content", children = { grandchild } })
            local root = make_element({ children = { middle } })
            luassert.has_error(function()
                validator.validate(root, "root")
            end)
        end)

        it("should succeed when node is nil", function()
            validator.validate(nil, "root")
        end)
    end)
end)
