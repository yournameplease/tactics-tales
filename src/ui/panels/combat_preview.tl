require("src/ui/box")
require("src/ui/panels/text_node")
require("src/ui/panels/portrait_box")

global record UnitInfo
    is UIElement

end
setmetatable(UnitInfo, { __index = Box })

local function get_preview_text(state: GameContext): {string}
    local attacker = state.acting_unit
    local defender = state.hovered_unit
    local preview = state.combat_calculator:preview_combat(attacker, defender).steps

    local out = {
        attacker.character.name .." -> ".. defender.character.name,
        "Hit: "..preview[1].hit.."%",
        "Dmg: "..preview[1].dmg,
    }
    if preview[2] ~= nil then
        add(out, attacker.character.name .." <- ".. defender.character.name)
        add(out, "Hit: "..preview[2].hit.."%")
        add(out, "Dmg: "..preview[2].dmg)
    else
        add(out, "No counterattack!")
        add(out, "")
        add(out, "")
    end
    return out
end

function UnitInfo.new(props: UIElement): UnitInfo
    props.dir = "row"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true

    local self = Box.new(props) as UnitInfo
    setmetatable(self, { __index = UnitInfo })

    local attacker_portrait = PortraitBox.new(function(state: GameContext): BattleUnit return state.acting_unit end)
    local defender_portrait = PortraitBox.new(function(state: GameContext): BattleUnit return state.hovered_unit end)

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
