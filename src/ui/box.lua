local Box = {}
Box.__index = Box -- TODO: ?

function Box.new(props)
    local self = setmetatable({}, Box)
    self.x = props.x or 0
    self.y = props.y or 0
    self.w = props.w or 0
    self.h = props.h or 0

    -- margin inside the view window, mainly used for drawing the shaded box at an offset
    if type(props.internal_margin) == "table" then
        self.internal_margin = {
            t = props.internal_margin.t or 0,
            b = props.internal_margin.b or 0,
            l = props.internal_margin.l or 0,
            r = props.internal_margin.r or 0
        }
    else
        local m = props.internal_margin or 0
        self.internal_margin = {t=m, b=m, l=m, r=m}
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
    self.gap = props.gap or 3
    self.padding = props.padding or 2
    self.decoration_padding = props.decoration_padding or self.padding - 1
    self.decoration = props.decoration -- "embossed" or "recessed"

    self.children = {}

    if self.decoration_padding < 0 then self.decoration_padding = 0 end
    assert(self.decoration_padding < self.padding or self.decoration_padding == 0)
    return self
end

function Box:add(child)
    add(self.children, child)
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
        self._calculated_w = self.w + self.internal_margin.l + self.internal_margin.r
        self._calculated_h = self.h + self.internal_margin.t + self.internal_margin.b
        --LOG.info("Measured", self._calculated_w, self._calculated_h)
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
        -- Note: We pass 0 or math.huge because we are in 'auto' mode,
        -- so we don't enforce a strict limit yet.
        if child.measure then
            child:measure()
        end

        -- Get child's total footprint (Size + Margins)
        local child_outer_w = (child._calculated_w or child.w) + (child.internal_margin and (child.internal_margin.l + child.internal_margin.r) or 0)
        local child_outer_h = (child._calculated_h or child.h) + (child.internal_margin and (child.internal_margin.t + child.internal_margin.b) or 0)

        if is_row then
            content_w = content_w + child_outer_w
            content_h = max(content_h, child_outer_h)
            if i > 1 then content_w = content_w + self.gap end
        else
            content_w = max(content_w, child_outer_w)
            content_h = content_h + child_outer_h
            if i > 1 then content_h = content_h + self.gap end
        end
    end

    -- C. Set our calculated size (Content + Padding)
    self._calculated_w = self.auto_width and (content_w + self.padding*2) or self.w
    self._calculated_h = self.auto_height and (content_h + self.padding*2) or self.h
end

-- =========================================================
-- PASS 2: ARRANGE (Top-Down)
-- Distribute space and set final X/Y
-- =========================================================
function Box:layout(parent_x, parent_y)
    -- Use calculated sizes if available, otherwise fixed
    local my_w = self._calculated_w or self.w
    local my_h = self._calculated_h or self.h

    -- Apply our own position (usually passed from parent)
    -- If no parent (root), use self.x/y
    self.x = parent_x or self.x
    self.y = parent_y or self.y

    local is_row = (self.dir == "row")

    -- 1. Calculate Free Space for Flex
    local used_space = self.padding * 2
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
            local child_w = child._calculated_w or child.w
            local child_h = child._calculated_h or child.h
            local cm = child.internal_margin or {t=0,b=0,l=0,r=0}

            if is_row then
                used_space = used_space + child_w + cm.l + cm.r
            else
                used_space = used_space + child_h + cm.t + cm.b
            end
        end
    end

    -- 2. Distribute Children
    local cx = self.x + self.padding + self.internal_margin.l
    local cy = self.y + self.padding + self.internal_margin.t
    local total_size = is_row and my_w or my_h
    local remaining = max(0, total_size - used_space)
    local px_per_flex = (total_flex > 0) and (remaining / total_flex) or 0

    for _, child in ipairs(self.children) do
        -- Calculate Final Child Size
        local child_w = child._calculated_w or child.w
        local child_h = child._calculated_h or child.h

        -- Handle Flex
        if child.flex_grow > 0 and total_flex > 0 then
            local added = flr(child.flex_grow * px_per_flex)
            if is_row then child_w = added
            else child_h = added end
        end

        if self.cross_stretch then
            if is_row then
                child_h = self.h - (self.padding * 2)
            else
                child_w = self.w - (self.padding * 2)
            end
        end
        -- Recurse Layout
        if child.layout then
            -- Temporarily override width/height with calculated layout size
            -- so the child knows its constraints
            local old_w, old_h = child.w, child.h
            child.w, child.h = child_w, child_h

            child:layout(cx, cy)

            -- Restore props (optional, depends if you want persistent state)
            --child.w, child.h = old_w, old_h
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

function Box:draw(state)
    if self.decoration == 'embossed' then
        self:draw_embossed()
    elseif self.decoration == 'recessed' then
        self:draw_recessed()
    end

    -- Debug rectangle
    --LOG.info(self.x, self.y, self._calculated_w, self._calculated_h, self.padding, self.internal_margin.l, self.internal_margin.t)
    LOG.info(self.x, self.y, self.w, self.h, self.padding, self.internal_margin.l, self.internal_margin.t)
    rrect(
            self.x+self.padding+self.internal_margin.l,
            self.y+self.padding+self.internal_margin.t,
            self.w - 2*self.padding,
            self.h - 2*self.padding,
            0, 14)

    -- 2. Draw Children
    for _, child in ipairs(self.children) do
        child:draw(state)
    end
end

function Box:draw_embossed()
    self:draw_shaded(UI_MANAGER.THEME.COLOR_DECORATION_HIGHLIGHT, UI_MANAGER.THEME.COLOR_DECORATION_SHADOW, UI_MANAGER.THEME.COLOR_DECORATION_PRIMARY)
end

function Box:draw_recessed()
    self:draw_shaded(UI_MANAGER.THEME.COLOR_DECORATION_SHADOW, UI_MANAGER.THEME.COLOR_DECORATION_HIGHLIGHT, UI_MANAGER.THEME.COLOR_INTERIOR)
    self:draw_shaded_dividers(UI_MANAGER.THEME.COLOR_DECORATION_SHADOW, UI_MANAGER.THEME.COLOR_DECORATION_HIGHLIGHT, UI_MANAGER.THEME.COLOR_DECORATION_PRIMARY)
end

function Box:draw_shaded(color_ne, color_sw, color_interior)
    -- TODO: 45 degree slant (draw lines in loop)
    local x = self.x + self.internal_margin.l
    local y = self.y + self.internal_margin.t
    local w = self.w - (self.internal_margin.l + self.internal_margin.r)
    local h = self.h - (self.internal_margin.t + self.internal_margin.b)
    local pad = self.decoration_padding
    if pad ~= 0 then
        rectfill(
                x,
                y+pad-1,
                x+pad-1,
                y+h-1,
                color_sw
        )
        rectfill(
                x,
                y+h-1,
                x+w-1,
                y+h-1,
                color_sw
        )
        rectfill(
                x,
                y,
                x+w-1,
                y+pad-1,
                color_ne
        )
        rectfill(
                x+w-pad,
                y,
                x+w-1,
                y+h-1-pad,
                color_ne
        )
    end
    rectfill(
            x+pad,
            y+pad,
            x+w-1-pad,
            y+h-1-pad,
            color_interior
    )
end

function Box:draw_shaded_dividers(color_ne, color_sw, color_interior)
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
            --    rectfill(
            --            x,
            --            c_y - gap_h + pad,
            --            x + w -1,
            --            c_y - pad,
            --            color_interior
            --    )
            --    rectfill(
            --        x,
            --        c_y - pad + 1,
            --        x + w -1,
            --        c_y,
            --        color_ne
            --    )
            --    rectfill(
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
                rectfill(
                        x,
                        c_y - gap_h + pad,
                        x + w -1,
                        c_y - pad,
                        color_interior
                )
                rectfill(
                    x,
                    c_y - gap_h,
                    x + w -1,
                    c_y - gap_h + pad - 1,
                    color_sw
                )
                rectfill(
                    x,
                    c_y - pad + 1,
                    x + w -1,
                    c_y,
                    color_ne
                )
            elseif self.dir == "row" then
                local prev_child = self.children[i]
                local next_child = self.children[i]
                local c_x = next_child.x + next_child.internal_margin_x
                local gap_w = self.gap
                local y_prev = prev_child.y + prev_child.internal_margin_y
                local h_prev = prev_child.h
                local y_next = next_child.y + next_child.internal_margin_y
                local h_next = next_child.h
                rectfill(
                        c_x - gap_w + pad,
                        y,
                        c_x - pad,
                        y + h -1,
                        color_interior
                )
                rectfill(
                    c_x - gap_w,
                    y_prev,
                    c_x - gap_w + pad - 1,
                    h_prev + h_prev -1,
                    color_sw
                )
                rectfill(
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

return Box