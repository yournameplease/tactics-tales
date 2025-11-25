local Box = include "src/ui/box.lua"

local PortraitBox = {}
setmetatable(PortraitBox, { __index = Box })

local BACKGROUND_SPRITE = 7 + 3 * 256

function PortraitBox.new()
    local box = Box.new({ w=20, h=24 })
    setmetatable(box, {__index = PortraitBox})
    return box
end

function PortraitBox:draw(state)
    Box.draw(self, state)

    local unit = state:get_selected_unit()
    if unit then
        -- TODO: magic numbers galore
        spr(BACKGROUND_SPRITE, self.x, self.y+8)
        -- Use the renderer we defined previously
        unit:draw(self.x+2, self.y+12, unit.side, true, false)
    end
end

return PortraitBox