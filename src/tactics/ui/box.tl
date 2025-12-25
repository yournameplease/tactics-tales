require("src/tactics/types")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/ui/theme")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager

global record Margin
    t: integer
    b: integer
    l: integer
    r: integer
end

global enum BoxDirection
    "col"
    "row"
end

global enum DecorationStyle
    "embossed"
    "recessed"
    "border"
end

global interface UIElement
    x: integer
    y: integer
    w: integer
    -- _calculated_w: integer
    h: integer
    -- _calculated_h: integer
    internal_margin: Margin
    auto_width: boolean
    auto_height: boolean
    flex_grow: integer
    cross_stretch: boolean
    dir: BoxDirection
    gap: integer
    padding: integer
    decoration_padding: integer
    decoration: DecorationStyle
    transparent: boolean
    children: { Box }

    add: function(self, UIElement): UIElement
    measure: function(self)
    layout: function(self, integer, integer)
    draw: function(self, UIContextManager, DrawTargetManager, UITheme)
end

global record Box
    is UIElement
    -- x: integer
    -- y: integer
    -- w: integer
    _calculated_w: integer
    -- h: integer
    _calculated_h: integer
    -- internal_margin: Margin
    -- auto_width: boolean
    -- auto_height: boolean
    -- flex_grow: integer
    -- cross_stretch: boolean
    -- dir: BoxDirection
    -- gap: integer
    -- padding: integer
    -- decoration_padding: integer
    -- decoration: DecorationStyle
    -- children: { Box }
end

function Box.new(props: UIElement): Box
    local self: Box = setmetatable({}, { __index = Box})
    self.x = props.x or 0
    self.y = props.y or 0
    self.w = props.w or 0
    self.h = props.h or 0

    -- margin inside the view window, mainly used for drawing the shaded box at an offset
    if props.internal_margin ~= nil then
        self.internal_margin = {
            t = props.internal_margin.t or 0,
            b = props.internal_margin.b or 0,
            l = props.internal_margin.l or 0,
            r = props.internal_margin.r or 0
        }
        self.decoration_padding = props.decoration_padding or 0
    else
        self.padding = props.padding or 2
        self.internal_margin = {
            t = self.padding,
            b = self.padding,
            l = self.padding,
            r = self.padding
        }
        self.decoration_padding = props.decoration_padding or self.padding - 1
    end

    -- calculate width/height based on children
    self.auto_width = props.auto_width or false
    self.auto_height = props.auto_height or false
    -- proportional flex amount
    self.flex_grow = props.flex_grow or 0
    -- If true, children expand to fill the cross-axis (e.g. width in a column)
    self.cross_stretch = props.cross_stretch ~= false

    -- Layout properties
    self.dir = props.dir or "col" -- "row" or "col"
    self.gap = props.gap or 1
    self.decoration = props.decoration -- "embossed" or "recessed"
    self.transparent = props.transparent == true

    self.children = {}

    if self.decoration_padding < 0 then self.decoration_padding = 0 end

    assert(not (self.flex_grow > 0  and (self.auto_width and self.auto_height)), "Cannot flex grow with auto_width and auto_height")
    assert(
        self.decoration_padding == 0
        or
        (
            self.decoration_padding < self.internal_margin.t and
            self.decoration_padding < self.internal_margin.b and
            self.decoration_padding < self.internal_margin.l and
            self.decoration_padding < self.internal_margin.r
        )
    )
    return self
end

-- utility constructors

function Box.flex_col(): Box
    return Box.new({ dir = "col", auto_width = true})
end

function Box.flex_row(): Box
    return Box.new({ dir = "row", auto_height = true})
end

-- good for lazy justification
function Box.spacer(grow: integer): Box
    return Box.new({ flex_grow = grow, transparent = true})
end

function Box:add(child: UIElement): UIElement
    pt.add(self.children, child as Box) -- Note: casting
    return child -- Return child for chaining
end

-- =========================================================
-- PASS 1: MEASURE (Bottom-Up)
-- Calculate intrinsic size of children, then self
-- =========================================================
function Box:measure()
    -- A. If we are fixed size, we don't care about children (optimization)
    -- EXCEPT if we contain content that might overflow (not handled here yet)
    if not self.auto_width and not self.auto_height then
        self._calculated_w = self.w
        self._calculated_h = self.h
        -- We still measure children so they know their own size
        for _, child in ipairs(self.children) do
            if child.measure then child:measure() end
        end
        return
    end

    -- B. Measure Children to determine our own size
    local content_w, content_h = 0, 0
    local is_row = (self.dir == "row")

    for i, child in ipairs(self.children) do
        -- Recursively measure child
        if child.measure then
            child:measure()
        end

        -- Get child's total footprint (Size + Margins)
        local child_outer_w = (child._calculated_w or child.w) 
        local child_outer_h = (child._calculated_h or child.h) 

        if is_row then
            content_w = content_w + child_outer_w
            content_h = pt.max(content_h, child_outer_h)
            if i > 1 then content_w = content_w + self.gap end
        else
            content_w = pt.max(content_w, child_outer_w)
            content_h = content_h + child_outer_h
            if i > 1 then content_h = content_h + self.gap end
        end
    end

    -- C. Set our calculated size (Content + Padding)
    self._calculated_w = self.auto_width and (content_w+self.internal_margin.l+self.internal_margin.r) or self.w
    self._calculated_h = self.auto_height and (content_h+self.internal_margin.t+self.internal_margin.b) or self.h
end

-- =========================================================
-- PASS 2: ARRANGE (Top-Down)
-- Distribute space and set final X/Y
-- =========================================================
function Box:layout(parent_x: integer, parent_y: integer)
    -- Use calculated sizes if available, otherwise fixed
    local my_w = (self._calculated_w or self.w) - self.internal_margin.l - self.internal_margin.r
    local my_h = (self._calculated_h or self.h) - self.internal_margin.t - self.internal_margin.b

    -- Apply our own position (usually passed from parent)
    -- If no parent (root), use self.x/y
    self.x = parent_x or self.x
    self.y = parent_y or self.y

    local is_row = (self.dir == "row")

    -- 1. Calculate Free Space for Flex
    local used_space = 0
    local total_flex = 0

    -- We assume margins were accounted for in the Measure pass size

    for i, child in ipairs(self.children) do
        -- Add Gap
        if i > 1 then used_space = used_space + self.gap end

        -- Add Child Fixed Size (Size + Margin)
        -- Important: If child is flex_grow > 0 but we are auto_size,
        -- flex is effectively disabled for that axis.
        if child.flex_grow > 0 and not (is_row and self.auto_width) and not (not is_row and self.auto_height) then
            total_flex = total_flex + child.flex_grow
            -- Don't add to used_space yet, flex takes remainder
        else
            local child_w = (child._calculated_w or child.w)
            local child_h = (child._calculated_h or child.h)

            if is_row then
                used_space = used_space + child_w
            else
                used_space = used_space + child_h
            end
        end
    end

    -- 2. Distribute Children
    local cx = self.x + self.internal_margin.l
    local cy = self.y + self.internal_margin.t
    local total_size = is_row and my_w or my_h
    local remaining = pt.max(0, total_size - used_space)
    local px_per_flex = (total_flex > 0) and (remaining / total_flex) or 0

    for _, child in ipairs(self.children) do
        -- Calculate Final Child Size
        local child_w = child._calculated_w or child.w
        local child_h = child._calculated_h or child.h

        -- Handle Flex
        if child.flex_grow > 0 and total_flex > 0 then
            local added = pt.flr(child.flex_grow * px_per_flex)
            if is_row then child_w = added
            else child_h = added end
        end

        if self.cross_stretch then
            if is_row then
                child_h = self.h - self.internal_margin.t - self.internal_margin.b
            else
                child_w = self.w - self.internal_margin.l - self.internal_margin.r 
            end
        end
        -- Recurse Layout
        if child.layout then
            child.w, child.h = child_w, child_h
            child:layout(cx, cy)
        end

        -- Advance Cursor
        if is_row then
            cx = cx + child_w + self.gap
            cy = cy
        else
            cy = cy + child_h + self.gap
            cx = cx
        end
    end
end

function Box:draw_shaded(color_ne: Color, color_sw: Color, color_interior: Color)
    -- TODO: 45 degree slant (draw lines in loop)
    local x = self.x + self.internal_margin.l
    local y = self.y + self.internal_margin.t
    local w = self.w - (self.internal_margin.l + self.internal_margin.r)
    local h = self.h - (self.internal_margin.t + self.internal_margin.b)
    local pad = self.decoration_padding
    if pad ~= 0 then
        pt.rectfill(
                x,
                y+pad-1,
                x+pad-1,
                y+h-1,
                color_sw
        )
        pt.rectfill(
                x,
                y+h-1,
                x+w-1,
                y+h-1,
                color_sw
        )
        pt.rectfill(
                x,
                y,
                x+w-1,
                y+pad-1,
                color_ne
        )
        pt.rectfill(
                x+w-pad,
                y,
                x+w-1,
                y+h-1-pad,
                color_ne
        )
    end
    pt.rectfill(
            x+pad,
            y+pad,
            x+w-1-pad,
            y+h-1-pad,
            color_interior
    )
end

function Box:draw_shaded_dividers(color_ne: Color, color_sw: Color, color_interior: Color)
    -- TODO: 45 degree slant (draw lines in loop)
    local x = self.x + self.internal_margin.l
    local y = self.y + self.internal_margin.t
    local w = self.w - (self.internal_margin.l + self.internal_margin.r)
    local h = self.h - (self.internal_margin.t + self.internal_margin.b)
    local pad = self.decoration_padding

    if #self.children > 1 and self.gap > 2 * self.decoration_padding then
        for i = 2, #self.children do
            --if self.dir == "col" then
            --    local child = self.children[i]
            --    local c_y = child.y + child.internal_margin.t
            --    local gap_h = self.gap
            --    pt.rectfill(
            --            x,
            --            c_y - gap_h + pad,
            --            x + w -1,
            --            c_y - pad,
            --            color_interior
            --    )
            --    pt.rectfill(
            --        x,
            --        c_y - pad + 1,
            --        x + w -1,
            --        c_y,
            --        color_ne
            --    )
            --    pt.rectfill(
            --        x,
            --        c_y - gap_h,
            --        x + w -1,
            --        c_y - gap_h + pad - 1,
            --        color_sw
            --    )
            --
            --    end
            if self.dir == "col" then
                local child = self.children[i]
                local c_y = child.y + child.internal_margin.t
                local gap_h = self.gap
                pt.rectfill(
                        x,
                        c_y - gap_h + pad,
                        x + w -1,
                        c_y - pad,
                        color_interior
                )
                pt.rectfill(
                    x,
                    c_y - gap_h,
                    x + w -1,
                    c_y - gap_h + pad - 1,
                    color_sw
                )
                pt.rectfill(
                    x,
                    c_y - pad + 1,
                    x + w -1,
                    c_y,
                    color_ne
                )
            elseif self.dir == "row" then
                local prev_child = self.children[i]
                local next_child = self.children[i]
                local c_x = next_child.x + next_child.internal_margin.l
                local gap_w = self.gap
                local y_prev = prev_child.y + prev_child.internal_margin.t
                local h_prev = prev_child.h
                local y_next = next_child.y + next_child.internal_margin.t
                local h_next = next_child.h
                pt.rectfill(
                        c_x - gap_w + pad,
                        y,
                        c_x - pad,
                        y + h -1,
                        color_interior
                )
                pt.rectfill(
                    c_x - gap_w,
                    y_prev,
                    c_x - gap_w + pad - 1,
                    h_prev + h_prev -1,
                    color_sw
                )
                pt.rectfill(
                    c_x - pad + 1,
                    y_next,
                    c_x,
                    y_next + h_next -1,
                    color_ne
                )
            end
        end
    end
end

function Box:draw_embossed(ui_theme: UITheme)
    self:draw_shaded(ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_PRIMARY)
end

function Box:draw_recessed(ui_theme: UITheme)
    self:draw_shaded(ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_INTERIOR)
    self:draw_shaded_dividers(ui_theme.COLOR_DECORATION_SHADOW, ui_theme.COLOR_DECORATION_HIGHLIGHT, ui_theme.COLOR_DECORATION_PRIMARY)
end

function Box:draw_border(ui_theme: UITheme)
    local d_pad = self.decoration_padding
    local x = self.x + self.internal_margin.l - d_pad
    local y = self.y + self.internal_margin.t - d_pad
    local w = self.w - (self.internal_margin.l + self.internal_margin.r - 2*d_pad)
    local h = self.h - (self.internal_margin.t + self.internal_margin.b - 2*d_pad)
    local r = pt.max(0, d_pad-1)
    pt.rrect(x, y, w, h, r, ui_theme.COLOR_DECORATION_PRIMARY)
end

function Box:draw_solid(ui_theme: UITheme)
    local x = self.x
    local y = self.y
    local w = self.w
    local h = self.h
    pt.rrectfill(x, y, w, h, 0, ui_theme.COLOR_INTERIOR)
end

function Box._draw(self: UIElement, state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    local box = self as Box -- Cast!  All classes inherit from box though

    if not box.transparent then
        box:draw_solid(ui_theme)
    end
    
    if box.decoration == 'embossed' then
        box:draw_embossed(ui_theme)
    elseif box.decoration == 'recessed' then
        box:draw_recessed(ui_theme)
    elseif box.decoration == 'border' then
        box:draw_border(ui_theme)
    end

    -- Debug rectangle
    -- LOG.trace(box.x, box.y, box.w, box.h)
    --     pt.rrect(
    --             box.x+box.internal_margin.l-box.decoration_padding,
    --             box.y+box.internal_margin.t-box.decoration_padding,
    --             box.w - (box.internal_margin.l+box.internal_margin.r)+2*box.decoration_padding,
    --             box.h - (box.internal_margin.t+box.internal_margin.b)+2*box.decoration_padding,
    --             0, 14)
        -- pt.rrect(
        --         box.x+box.padding+box.internal_margin.l,
        --         box.y+box.padding+box.internal_margin.t,
        --         box._calculated_w - 2*box.padding,
        --         box._calculated_h - 2*box.padding,
        --         0, 28)

    -- 2. Draw Children
    for _, child in ipairs(box.children) do
        child:draw(state, draw_target_manager, ui_theme)
    end
end

function Box:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    Box._draw(self, state, draw_target_manager, ui_theme)
end

return Box
