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

    local attacker_portrait = PortraitBox.new(function(state) return state:get_acting_unit()  end)
    local defender_portrait = PortraitBox.new(function(state) return state:get_selected_unit()  end)

    local preview_text = TextNode.new({
        flex_grow = 1,
        rows = 6,
        func = function(state)
            local u = state:get_selected_unit()
            if not u then return { "", "", "", "", "", "", } end

            local w = u.weapon

            return {
                "", "", "", "", "", ""
            }
        end
    })

    self:add(attacker_portrait)
    self:add(preview_text)
    self:add(defender_portrait)

    return self
end

return UnitInfo