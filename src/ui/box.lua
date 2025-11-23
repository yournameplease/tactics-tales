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
    self.gap = props.gap or 0
    self.padding = props.padding or 0
    self.bg_color = props.bg_color

    self.children = {}
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
    -- 1. Draw Background (if any)
    if self.bg_color then
        rectfill(self.x, self.y, self.x+self.w, self.y+self.h, self.bg_color)
    end

    -- 2. Draw Children
    for _, child in ipairs(self.children) do
        child:draw(state)
    end
end

return Box