local Box = {}
Box.__index = Box -- TODO: ?

function Box.new(props)
    local self = setmetatable({}, Box)
    self.x = props.x or 0
    self.y = props.y or 0
    self.w = props.w or 0
    self.h = props.h or 0

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

function Box:layout()local is_row = (self.dir == "row")

    -- ---------------------------------------------------------
    -- PASS 1: Measurement & Flex Calculation
    -- ---------------------------------------------------------
    local total_flex = 0
    local used_space = (self.padding * 2)
    local num_children = #self.children

    -- Add gap space
    if num_children > 1 then
        used_space = used_space + (self.gap * (num_children - 1))
    end

    for _, child in ipairs(self.children) do
        if child.flex_grow > 0 then
            total_flex = total_flex + child.flex_grow
        else
            -- For fixed items, we just add their current requested size
            local size = is_row and child.w or child.h
            used_space = used_space + size
        end
    end

    -- Calculate the size of 1 "flex unit"
    local total_size = is_row and self.w or self.h
    local remaining_space = math.max(0, total_size - used_space)
    local px_per_flex = 0

    if total_flex > 0 then
        assert(remaining_space % total_flex == 0, "Flex remainder not implemented!")
        px_per_flex = remaining_space / total_flex -- TODO: remainder!
    end

    -- ---------------------------------------------------------
    -- PASS 2: Positioning & Sizing
    -- ---------------------------------------------------------
    local cx, cy = self.x + self.padding, self.y + self.padding

    for _, child in ipairs(self.children) do
        -- A. Apply Flex Sizing (Main Axis)
        if child.flex_grow > 0 then
            local new_size = math.floor(child.flex_grow * px_per_flex)
            if is_row then
                child.w = new_size
            else
                child.h = new_size
            end
        end

        -- B. Apply Cross-Axis Stretch
        if self.cross_stretch then
            if is_row then
                child.h = self.h - (self.padding * 2)
            else
                child.w = self.w - (self.padding * 2)
            end
        end

        -- C. Set Position
        child.x = cx
        child.y = cy

        -- D. Recursively Layout Child
        -- (Child needs valid x,y,w,h before it can layout its own children)
        if child.layout then child:layout() end -- todo : ???

        -- E. Advance Cursor
        if is_row then
            cx = cx + child.w + self.gap
        else
            cy = cy + child.h + self.gap
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
    rrect(self.x+self.padding, self.y+self.padding, self.w - 2*self.padding, self.h - 2*self.padding, 0, 14)

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
end

function Box:draw_shaded(color_ne, color_sw, color_interior)
    -- TODO: 45 degree slant (draw lines in loop)
    -- TODO: child separators
    if self.decoration_padding ~= 0 then
        rectfill(
                self.x,
                self.y+self.decoration_padding-1,
                self.x+self.decoration_padding-1,
                self.y+self.h-1,
                color_sw
        )
        rectfill(
                self.x,
                self.y+self.h-1,
                self.x+self.w-1,
                self.y+self.h-1,
                color_sw
        )
        rectfill(
                self.x,
                self.y,
                self.x+self.w-1,
                self.y+self.decoration_padding-1,
                color_ne
        )
        rectfill(
                self.x+self.w-self.decoration_padding,
                self.y,
                self.x+self.w-1,
                self.y+self.h-1-self.decoration_padding,
                color_ne
        )
    end
    rectfill(
            self.x+self.decoration_padding,
            self.y+self.decoration_padding,
            self.x+self.w-1-self.decoration_padding,
            self.y+self.h-1-self.decoration_padding,
            color_interior
    )
end

return Box