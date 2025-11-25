local Box = include "src/ui/box.lua"
local TextNode = include "src/ui/panels/text_node.lua"
local PortraitBox = include "src/ui/panels/portrait_box.lua"

local UnitInfo = {}
setmetatable(UnitInfo, { __index = Box })

function UnitInfo.new(props)
    props.dir = "row"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true

    local self = Box.new(props)
    setmetatable(self, { __index = UnitInfo })

    self:add(PortraitBox.new())

    local info_col = self:add(Box.new({
        auto_height = 1,
        dir = "col",
        gap = 2
    }))

    -- ROW 1: Name and Level
    info_col:add(TextNode.new({
        func = function(state)
            local u = state:get_selected_unit()
            if not u then return { "No Unit Selected" } end
            return { u.name .. " Lv." .. 1 }
        end
    }))

    -- ROW 2-4: HP, Weapon
    info_col:add(TextNode.new({
        rows = 3,
        func = function(state)
            local u = state:get_selected_unit()
            if not u then return { "", "", "" } end

            local w = u.weapon

            return {
                "HP: " .. u.hp_current .. "/" .. u.hp_max,
                w and w.name or "Unarmed",
                w and ("(" .. w.accuracy .. "% for " .. w.damage .. " dmg)") or "",
            }
        end
    }))

    return self
end

return UnitInfo