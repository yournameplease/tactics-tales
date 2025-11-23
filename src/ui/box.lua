local Box = {}
Box.__index = Box -- TODO: ?

function Box.new(props)
    local self = setmetatable({}, Box)
    self.x = props.x or 0
    self.y = props.y or 0
    self.w = props.w or 0
    self.h = props.h or 0

    -- Layout properties
    self.dir = props.dir or "col" -- "row" or "col"
    self.gap = props.gap or 3
    self.padding = props.padding or 2
    self.decoration_padding = props.decoration_padding or self.padding - 1
    self.decoration = props.decoration -- "embossed" or "recessed"

    self.children = {}

    assert(self.decoration_padding < self.padding)
    return self
end

function Box:add(child)
    add(self.children, child)
    return child -- Return child for chaining
end

-- The "Flexbox" magic: Recalculate children positions based on parent
function Box:layout()
    local cx, cy = self.x + self.padding, self.y + self.padding

    for _, child in ipairs(self.children) do
        child.x = cx
        child.y = cy

        -- Let the child calculate its own internal layout
        if child.layout then child:layout() end

        -- Advance cursor for next sibling
        if self.dir == "row" then
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
                self.y+self.h,
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
                self.x+self.w,
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