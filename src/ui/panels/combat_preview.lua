local Box = include "src/ui/box.lua"
local TextNode = include "src/ui/panels/text_node.lua"
local PortraitBox = include "src/ui/panels/portrait_box.lua"

local UnitInfo = {}
setmetatable(UnitInfo, { __index = Box })

local function get_preview_text(state)
    local attacker = state:get_acting_unit()
    local defender = state:get_selected_unit()
    local preview = state.combat_calculator.preview_combat(attacker, defender).steps

    local out = {
        attacker.name .." -> ".. defender.name,
        "Hit: "..preview[1].hit.."%",
        "Dmg: "..preview[1].dmg,
    }
    if preview[2] ~= nil then
        add(out, attacker.name .." <- ".. defender.name)
        add(out, "Hit: "..preview[2].hit.."%")
        add(out, "Dmg: "..preview[2].dmg)
    else
        add(out, "No counterattack!")
        add(out, "")
        add(out, "")
    end
    return out
end

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
        func = get_preview_text
    })

    self:add(attacker_portrait)
    self:add(preview_text)
    self:add(defender_portrait)

    return self
end

return UnitInfo