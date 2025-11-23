Box = include "src/ui/box.lua"

local UnitInfo = {}

function UnitInfo:draw(state)
    Box.draw(self, state)

    local unit = state.selected_unit
    if unit then
        print("HP: "..unit.hp, self.x + 5, self.y + 5, 7)
    else
        print("No Unit Selected", self.x + 5, self.y + 5, 6)
    end
end

setmetatable(UnitInfo, { __index = Box})

return UnitInfo