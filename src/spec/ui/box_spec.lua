local luassert = require("luassert")

local box_module = require("src.tactics.ui.box")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal fixed-size element with no children.
--- Note: when using :layout(), it replaces the entire layout table, so dir, gap,
--- and padding must be included there (or use separate builder methods after).
---@param id string
---@param w integer
---@param h integer
---@return UIElement
local function make_fixed(id, w, h)
    return box_module.builder(id)
        :layout({ width = w, height = h })
        :build()
end

--- Build a fit_content element (col direction, no padding, no children).
---@param id string
---@return UIElement
local function make_fit(id)
    return box_module.builder(id)
        :direction("col")
        :container("modal")
        :build()
end

--- Build a row container with a fixed size and optional gap.
---@param id string
---@param w integer
---@param h integer
---@param gap? integer Defaults to 0.
---@return UIElement
local function make_row(id, w, h, gap)
    return box_module.builder(id)
        :layout({ width = w, height = h, dir = "row", gap = gap or 0 })
        :build()
end

--- Build a col container with a fixed size and optional gap.
---@param id string
---@param w integer
---@param h integer
---@param gap? integer Defaults to 0.
---@return UIElement
local function make_col(id, w, h, gap)
    return box_module.builder(id)
        :layout({ width = w, height = h, dir = "col", gap = gap or 0 })
        :build()
end

--- Run a single measure + apply_layout pass on an element at the origin.
---@param elem UIElement
---@param max_w integer
---@param max_h integer
local function do_layout(elem, max_w, max_h)
    elem:measure(1, true)
    elem:apply_layout(0, 0, max_w, max_h, true)
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.ui.box", function()

    -- -----------------------------------------------------------------------
    describe("builder / build defaults", function()

        it("defaults width to 'fill' when unset", function()
            local elem = box_module.builder("x"):build()
            luassert.are_equal("fill", elem.layout.width)
        end)

        it("defaults height to 'fit_content' when unset", function()
            local elem = box_module.builder("x"):build()
            luassert.are_equal("fit_content", elem.layout.height)
        end)

        it("sets flex_grow to 1 when width is fill", function()
            local elem = box_module.builder("x"):build()  -- width defaults to "fill"
            luassert.are_equal(1, elem.layout.flex_grow)
        end)

        it("sets flex_grow to 0 for a fit-content-only element", function()
            local elem = make_fit("x")
            luassert.are_equal(0, elem.layout.flex_grow)
        end)

        it("defaults dir to 'col'", function()
            local elem = box_module.builder("x"):build()
            luassert.are_equal("col", elem.layout.dir)
        end)

        it("defaults gap to 0", function()
            local elem = box_module.builder("x"):build()
            luassert.are_equal(0, elem.layout.gap)
        end)

        it("defaults all padding fields to 0", function()
            local elem = box_module.builder("x"):build()
            luassert.are_equal(0, elem.layout.padding.t)
            luassert.are_equal(0, elem.layout.padding.b)
            luassert.are_equal(0, elem.layout.padding.l)
            luassert.are_equal(0, elem.layout.padding.r)
        end)

        it("sets cacheable dirty flags to true on build", function()
            local elem = box_module.builder("x"):build()
            luassert.is_true(elem.cacheable.dirty_layout)
            luassert.is_true(elem.cacheable.dirty_draw)
        end)

        it("raises when flex_grow > 0 with both dimensions fit_content", function()
            luassert.has_error(function()
                box_module.builder("x")
                    :layout({ width = "fit_content", height = "fit_content", flex_grow = 1 })
                    :build()
            end)
        end)

        it("raises when decoration_padding exceeds any padding side", function()
            luassert.has_error(function()
                box_module.builder("x")
                    :layout({ width = "fit_content", height = "fill", padding = { t=2, b=2, l=2, r=2 } })
                    :style({ decoration_padding = 3, decoration = "embossed" })
                    :build()
            end)
        end)

        it("does not raise when decoration_padding equals all padding sides", function()
            -- should not throw
            box_module.builder("x")
                :layout({ width = "fit_content", height = "fill", padding = { t=3, b=3, l=3, r=3 } })
                :style({ decoration_padding = 3, decoration = "embossed" })
                :build()
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("UIBuilder:container preset", function()

        it("'block' on col dir gives fit_content height and fill width", function()
            local elem = box_module.builder("x"):direction("col"):container("block"):build()
            luassert.are_equal("fit_content", elem.layout.height)
            luassert.are_equal("fill", elem.layout.width)
        end)

        it("'block' on row dir gives fit_content width and fill height", function()
            local elem = box_module.builder("x"):direction("row"):container("block"):build()
            luassert.are_equal("fit_content", elem.layout.width)
            luassert.are_equal("fill", elem.layout.height)
        end)

        it("'panel' gives fill on both axes", function()
            local elem = box_module.builder("x"):direction("col"):container("panel"):build()
            luassert.are_equal("fill", elem.layout.width)
            luassert.are_equal("fill", elem.layout.height)
        end)

        it("'strip' on col dir gives fill height and fit_content width", function()
            local elem = box_module.builder("x"):direction("col"):container("strip"):build()
            luassert.are_equal("fill", elem.layout.height)
            luassert.are_equal("fit_content", elem.layout.width)
        end)

        it("'modal' gives fit_content on both axes", function()
            local elem = box_module.builder("x"):direction("col"):container("modal"):build()
            luassert.are_equal("fit_content", elem.layout.width)
            luassert.are_equal("fit_content", elem.layout.height)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("UIBuilder:padding", function()

        it("integer argument sets all four padding fields uniformly", function()
            -- :padding() must be called after :layout() to avoid being overwritten
            local elem = box_module.builder("x"):layout({ width = "fill", height = "fit_content" }):padding(4):build()
            luassert.are_equal(4, elem.layout.padding.t)
            luassert.are_equal(4, elem.layout.padding.b)
            luassert.are_equal(4, elem.layout.padding.l)
            luassert.are_equal(4, elem.layout.padding.r)
        end)

        it("Padding table sets each side independently", function()
            local elem = box_module.builder("x"):layout({ width = "fill", height = "fit_content" }):padding({ t = 1, b = 2, l = 3, r = 4 }):build()
            luassert.are_equal(1, elem.layout.padding.t)
            luassert.are_equal(2, elem.layout.padding.b)
            luassert.are_equal(3, elem.layout.padding.l)
            luassert.are_equal(4, elem.layout.padding.r)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:add", function()

        it("returns the added child for chaining", function()
            local parent = make_fit("parent")
            local child = make_fixed("child", 10, 10)
            local returned = parent:add(child)
            luassert.are_equal(child, returned)
        end)

        it("appends the child to self.children", function()
            local parent = make_fit("parent")
            local child = make_fixed("child", 10, 10)
            parent:add(child)
            luassert.are_equal(1, #parent.children)
            luassert.are_equal(child, parent.children[1])
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:measure — fixed size", function()

        it("sets rect.w and rect.h from the fixed dimensions", function()
            local elem = make_fixed("e", 30, 20)
            elem:measure(1, true)
            luassert.are_equal(30, elem.rect.w)
            luassert.are_equal(20, elem.rect.h)
        end)

        it("subtracts padding from content dimensions", function()
            -- Include padding inside the layout table so :layout() doesn't overwrite it
            local elem = box_module.builder("e")
                :layout({ width = 30, height = 20, padding = { t=3, b=3, l=3, r=3 } })
                :build()
            elem:measure(1, true)
            luassert.are_equal(24, elem.rect.c_w)  -- 30 - 3 - 3
            luassert.are_equal(14, elem.rect.c_h)  -- 20 - 3 - 3
        end)

        it("stores the depth in the rect", function()
            local elem = make_fixed("e", 10, 10)
            elem:measure(3, true)
            luassert.are_equal(3, elem.rect.depth)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:measure — fit_content col direction", function()

        it("height equals sum of child heights", function()
            local parent = make_fit("p")
            parent:add(make_fixed("a", 10, 5))
            parent:add(make_fixed("b", 10, 8))
            parent:measure(1, true)
            luassert.are_equal(13, parent.rect.h)
        end)

        it("width equals max of child widths", function()
            local parent = make_fit("p")
            parent:add(make_fixed("a", 15, 5))
            parent:add(make_fixed("b", 20, 5))
            parent:measure(1, true)
            luassert.are_equal(20, parent.rect.w)
        end)

        it("adds gap between children but not before the first", function()
            -- Arrange: col container, gap=4, three children of height 5
            local parent = box_module.builder("p")
                :direction("col")
                :layout({ width = "fit_content", height = "fit_content", gap = 4 })
                :build()
            parent:add(make_fixed("a", 10, 5))
            parent:add(make_fixed("b", 10, 5))
            parent:add(make_fixed("c", 10, 5))
            parent:measure(1, true)
            -- 3 children × 5h + 2 gaps × 4 = 23
            luassert.are_equal(23, parent.rect.h)
        end)

        it("accounts for padding in fit_content size", function()
            local parent = box_module.builder("p")
                :direction("col")
                :layout({ width = "fit_content", height = "fit_content", padding = { t=3, b=3, l=3, r=3 } })
                :build()
            parent:add(make_fixed("a", 10, 5))
            parent:measure(1, true)
            luassert.are_equal(10 + 6, parent.rect.w)  -- content + l + r
            luassert.are_equal(5  + 6, parent.rect.h)  -- content + t + b
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:measure — fit_content row direction", function()

        it("width equals sum of child widths", function()
            local parent = box_module.builder("p")
                :direction("row")
                :container("modal")
                :build()
            parent:add(make_fixed("a", 10, 5))
            parent:add(make_fixed("b", 12, 5))
            parent:measure(1, true)
            luassert.are_equal(22, parent.rect.w)
        end)

        it("height equals max of child heights", function()
            local parent = box_module.builder("p")
                :direction("row")
                :container("modal")
                :build()
            parent:add(make_fixed("a", 10, 5))
            parent:add(make_fixed("b", 10, 9))
            parent:measure(1, true)
            luassert.are_equal(9, parent.rect.h)
        end)

        it("adds gap between children in row direction", function()
            local parent = box_module.builder("p")
                :direction("row")
                :layout({ width = "fit_content", height = "fit_content", gap = 2, dir = "row" })
                :build()
            parent:add(make_fixed("a", 10, 5))
            parent:add(make_fixed("b", 10, 5))
            parent:measure(1, true)
            luassert.are_equal(22, parent.rect.w)  -- 10 + 2 + 10
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:measure — fill dimension", function()

        it("leaves rect.w nil when width is 'fill'", function()
            local elem = box_module.builder("e"):build()  -- width defaults to "fill"
            elem:measure(1, true)
            luassert.is_nil(elem.rect.w)
        end)

        it("leaves rect.h nil when height is 'fill'", function()
            local elem = box_module.builder("e"):direction("col"):container("panel"):build()
            -- panel → both "fill"
            elem:measure(1, true)
            luassert.is_nil(elem.rect.h)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:apply_layout — fill dimension resolution", function()

        it("fill width is set to max_w from parent", function()
            local elem = box_module.builder("e"):build()  -- width="fill"
            do_layout(elem, 100, 80)
            luassert.are_equal(100, elem.rect.w)
        end)

        it("fill height is set to max_h from parent", function()
            local elem = box_module.builder("e"):direction("col"):container("panel"):build()
            do_layout(elem, 100, 80)
            luassert.are_equal(80, elem.rect.h)
        end)

        it("positions element at parent_x, parent_y", function()
            local elem = make_fixed("e", 20, 20)
            do_layout(elem, 100, 100)
            luassert.are_equal(0, elem.rect.x)
            luassert.are_equal(0, elem.rect.y)
        end)

        it("content bounds account for asymmetric padding", function()
            -- Arrange: include padding inside layout table so it isn't lost
            local elem = box_module.builder("e")
                :layout({ width = 40, height = 30, padding = { t=2, b=3, l=4, r=5 } })
                :build()
            do_layout(elem, 100, 100)
            -- Assert
            luassert.are_equal(4,  elem.rect.c_x)   -- x=0 + padding.l=4
            luassert.are_equal(2,  elem.rect.c_y)   -- y=0 + padding.t=2
            luassert.are_equal(31, elem.rect.c_w)   -- 40 - 4 - 5
            luassert.are_equal(25, elem.rect.c_h)   -- 30 - 2 - 3
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:apply_layout — flex distribution", function()

        it("single flex child fills all remaining space in a row container", function()
            -- Arrange: row container 100px wide, one fixed 20px child, one spacer
            local parent = make_row("p", 100, 20)
            local fixed = make_fixed("fixed", 20, 20)
            local flex = box_module.spacer()
            parent:add(fixed)
            parent:add(flex)

            -- Act
            do_layout(parent, 100, 20)

            -- Assert: flex child gets 100 - 20 = 80
            luassert.are_equal(80, flex.rect.w)
        end)

        it("two equal flex children split remaining space evenly", function()
            local parent = make_row("p", 100, 20)
            parent:add(box_module.spacer())
            parent:add(box_module.spacer())

            do_layout(parent, 100, 20)

            luassert.are_equal(50, parent.children[1].rect.w)
            luassert.are_equal(50, parent.children[2].rect.w)
        end)

        it("non-flex child keeps its measured size", function()
            local parent = make_row("p", 100, 20)
            local fixed = make_fixed("fixed", 30, 20)
            parent:add(fixed)
            parent:add(box_module.spacer())

            do_layout(parent, 100, 20)

            luassert.are_equal(30, fixed.rect.w)
        end)

        it("cross-axis fill child gets container content height in a row layout", function()
            -- Arrange: row container with height 40; child with width=fit_content, height=fill
            local parent = make_row("p", 100, 40)
            -- A child that fills the cross-axis (height) of a row container
            local child = box_module.builder("c")
                :direction("col")
                :layout({ width = "fit_content", height = "fill", dir = "col" })
                :build()
            parent:add(child)

            do_layout(parent, 100, 40)

            luassert.are_equal(40, child.rect.h)
        end)

        it("respects gap when distributing flex space", function()
            -- Arrange: row container 100px, gap=10, two equal spacers
            local parent = make_row("p", 100, 20, 10)
            parent:add(box_module.spacer())
            parent:add(box_module.spacer())

            do_layout(parent, 100, 20)

            -- Total available for flex: 100 - 10 (gap) = 90, split in two → 45 each
            luassert.are_equal(45, parent.children[1].rect.w)
            luassert.are_equal(45, parent.children[2].rect.w)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:find_node_by_id", function()

        it("returns self when id matches", function()
            local elem = make_fixed("target", 10, 10)
            luassert.are_equal(elem, elem:find_node_by_id("target"))
        end)

        it("finds a direct child by id", function()
            local parent = make_fit("parent")
            local child = make_fixed("child", 10, 10)
            parent:add(child)
            luassert.are_equal(child, parent:find_node_by_id("child"))
        end)

        it("finds a deeply nested node by id", function()
            local root = make_fit("root")
            local mid = make_fit("mid")
            local deep = make_fixed("deep", 5, 5)
            root:add(mid)
            mid:add(deep)
            luassert.are_equal(deep, root:find_node_by_id("deep"))
        end)

        it("returns nil when id is not found", function()
            local elem = make_fixed("elem", 10, 10)
            luassert.is_nil(elem:find_node_by_id("nonexistent"))
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("box.find_topmost_selection", function()

        --- Build a laid-out element positioned and sized exactly, with optional hover event.
        ---@param id string
        ---@param x integer
        ---@param y integer
        ---@param w integer
        ---@param h integer
        ---@param hover_event table?
        ---@return UIElement
        local function make_placed(id, x, y, w, h, hover_event)
            local elem = make_fixed(id, w, h)
            elem:measure(1, true)
            elem:apply_layout(x, y, w, h, true)
            if hover_event then
                elem.menu_handling = { hover_event = hover_event }
            end
            return elem
        end

        --- Build a parent container for hit-testing; does not have menu_handling itself.
        ---@return UIElement
        local function make_parent()
            local p = make_fit("p")
            p.rect = { x = 0, y = 0, w = 100, h = 100, c_x = 0, c_y = 0, c_w = 100, c_h = 100, depth = 0 }
            return p
        end

        it("returns nil when mouse is outside all child bounds", function()
            local parent = make_parent()
            parent:add(make_placed("sel", 10, 10, 20, 20, { type = "button" }))
            local result = box_module.find_topmost_selection(parent, 50, 50)
            luassert.is_nil(result)
        end)

        it("returns hover_event when mouse is inside matching element", function()
            local parent = make_parent()
            local event = { type = "button" }
            parent:add(make_placed("sel", 10, 10, 20, 20, event))
            local result = box_module.find_topmost_selection(parent, 15, 15)
            luassert.are_equal(event, result)
        end)

        it("calls get_selection_at when hover_event is nil", function()
            local parent = make_parent()
            local event = { type = "grid" }
            local called = false
            local child = make_placed("sel", 10, 10, 20, 20, nil)
            child.menu_handling = {
                hover_event = nil,
                get_selection_at = function(_, _lx, _ly)
                    called = true
                    return event
                end,
            }
            parent:add(child)
            local result = box_module.find_topmost_selection(parent, 15, 15)
            luassert.are_equal(event, result)
            luassert.is_true(called)
        end)

        it("prefers a deeper child's selection over a shallower one", function()
            local parent = make_parent()
            local outer_event = { type = "outer" }
            local inner_event = { type = "inner" }
            -- outer covers (5,5)-(55,55), inner covers (10,10)-(30,30)
            local outer = make_placed("outer", 5, 5, 50, 50, outer_event)
            local inner = make_placed("inner", 10, 10, 20, 20, inner_event)
            outer:add(inner)
            parent:add(outer)
            local result = box_module.find_topmost_selection(parent, 15, 15)
            luassert.are_equal(inner_event, result)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:compute_children", function()

        it("does nothing when the key is unchanged", function()
            local original_children = {}
            local elem = make_fit("e")
            elem.children = original_children
            local key = 1
            elem.child_generator = {
                last_key = key,
                current_key = function(_) return key end,
                generate_children = function(_) return { make_fixed("x", 5, 5) } end,
            }
            ---@diagnostic disable-next-line: missing-fields
            elem:compute_children({})
            luassert.are_equal(original_children, elem.children)
        end)

        it("rebuilds children when the key changes", function()
            local elem = make_fit("e")
            local new_child = make_fixed("new", 5, 5)
            elem.child_generator = {
                last_key = 1,
                current_key = function(_) return 2 end,
                generate_children = function(_) return { new_child } end,
            }
            ---@diagnostic disable-next-line: missing-fields
            elem:compute_children({})
            luassert.are_equal(1, #elem.children)
            luassert.are_equal(new_child, elem.children[1])
        end)

        it("sets dirty_layout when key changes", function()
            local elem = make_fit("e")
            elem.cacheable.dirty_layout = false
            elem.child_generator = {
                last_key = 1,
                current_key = function(_) return 2 end,
                generate_children = function(_) return {} end,
            }
            ---@diagnostic disable-next-line: missing-fields
            elem:compute_children({})
            luassert.is_true(elem.cacheable.dirty_layout)
        end)

        it("updates last_key after rebuilding", function()
            local elem = make_fit("e")
            elem.child_generator = {
                last_key = 1,
                current_key = function(_) return 42 end,
                generate_children = function(_) return {} end,
            }
            ---@diagnostic disable-next-line: missing-fields
            elem:compute_children({})
            luassert.are_equal(42, elem.child_generator.last_key)
        end)

        it("does not dirty_layout when key is unchanged", function()
            local elem = make_fit("e")
            elem.cacheable.dirty_layout = false
            local key = 7
            elem.child_generator = {
                last_key = key,
                current_key = function(_) return key end,
                generate_children = function(_) return {} end,
            }
            ---@diagnostic disable-next-line: missing-fields
            elem:compute_children({})
            luassert.is_false(elem.cacheable.dirty_layout)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("Box:mark_dirty_layout", function()

        it("sets dirty_layout to true on self", function()
            local elem = make_fixed("e", 10, 10)
            elem.cacheable.dirty_layout = false
            elem:mark_dirty_layout()
            luassert.is_true(elem.cacheable.dirty_layout)
        end)

        it("bubbles dirty_layout to parent", function()
            local parent = make_fit("parent")
            local child = make_fixed("child", 10, 10)
            -- Set parent ref manually to isolate mark_dirty_layout from add()
            child.parent = parent
            parent.cacheable.dirty_layout = false
            child:mark_dirty_layout()
            luassert.is_true(parent.cacheable.dirty_layout)
        end)

        it("bubbles dirty_layout transitively to grandparent", function()
            local grandparent = make_fit("grandparent")
            local parent = make_fit("parent")
            local child = make_fixed("child", 10, 10)
            parent.parent = grandparent
            child.parent = parent
            grandparent.cacheable.dirty_layout = false
            child:mark_dirty_layout()
            luassert.is_true(grandparent.cacheable.dirty_layout)
        end)

        it("does not error when called on a root node with no parent", function()
            local root = make_fixed("root", 10, 10)
            luassert.has_no.error(function()
                root:mark_dirty_layout()
            end)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("box.spacer", function()

        it("creates an element with flex_grow = 1 by default", function()
            local s = box_module.spacer()
            luassert.are_equal(1, s.layout.flex_grow)
        end)

        it("accepts a custom grow value", function()
            local s = box_module.spacer(3)
            luassert.are_equal(3, s.layout.flex_grow)
        end)

        it("has fill on both axes", function()
            local s = box_module.spacer()
            luassert.are_equal("fill", s.layout.width)
            luassert.are_equal("fill", s.layout.height)
        end)

    end)

    -- -----------------------------------------------------------------------
    describe("layout.padding helper", function()

        it("sets all four sides to the given value", function()
            local p = box_module.layout.padding(5)
            luassert.are_equal(5, p.t)
            luassert.are_equal(5, p.b)
            luassert.are_equal(5, p.l)
            luassert.are_equal(5, p.r)
        end)

    end)

end)
