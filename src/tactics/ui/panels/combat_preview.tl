require("src/tactics/ui/box")
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/panels/portrait_box")
require("src/tactics/ui/ui_context_manager")
local combat_calculator = require("src/tactics/battle/combat/combat_calculator")

global record CombatPreview
    is UIElement

end
setmetatable(CombatPreview, { __index = Box })

local function get_preview_text(state: UIContextManager): {string}
    local attacker = state.battle_context.acting_unit
    local defender = state.battle_context.hovered_unit
    local attacker_tile = state.battle_context.destination
    local battle_map = state.battle_context.battle_map
    local preview = combat_calculator.preview_combat(attacker, defender, attacker_tile, battle_map).steps

    local out: {string} = {}
    if preview[1] ~= nil then 
            pt.add(out, attacker.character.name .." -> ".. defender.character.name)
            pt.add(out, "Hit: "..preview[1].hit_chance.."%")
            pt.add(out, "Dmg: "..preview[1].dmg)
    else
        pt.add(out, "No attack!")
        pt.add(out, "")
        pt.add(out, "")
        
    end
    if preview[2] ~= nil then
        pt.add(out, attacker.character.name .." <- ".. defender.character.name)
        pt.add(out, "Hit: "..preview[2].hit_chance.."%")
        pt.add(out, "Dmg: "..preview[2].dmg)
    else
        pt.add(out, "No counterattack!")
        pt.add(out, "")
        pt.add(out, "")
    end
    return out
end

function CombatPreview.new(props: UIElement): CombatPreview
    props.dir = "row"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true

    local self = Box.new(props) as CombatPreview
    setmetatable(self, { __index = CombatPreview })

    local attacker_portrait = PortraitBox.new(function(state: UIContextManager): BattleUnit return state.battle_context.acting_unit end)
    local left = Box.flex_col()
    left:add(attacker_portrait)
    left:add(Box.spacer())
    local defender_portrait = PortraitBox.new(function(state: UIContextManager): BattleUnit return state.battle_context.hovered_unit end)
    local right = Box.flex_col()
    right:add(defender_portrait)
    right:add(Box.spacer())

    local preview_text = TextNode.new({
        flex_grow = 1,
        rows = 6,
        func = get_preview_text
    })

    self:add(left)
    self:add(preview_text)
    self:add(right)

    return self
end

return CombatPreview
