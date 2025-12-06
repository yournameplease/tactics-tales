require("src/ui/box")
require("src/ui/panels/text_node")
require("src/ui/panels/portrait_box")

global record CombatPreview
    is UIElement

end
setmetatable(CombatPreview, { __index = Box })

local function get_preview_text(state: GameContext): {string}
    local attacker = state.acting_unit
    local defender = state.hovered_unit
    local attacker_tile = state.destination
    local preview = state.combat_calculator:preview_combat(attacker, defender, attacker_tile).steps

    local out: {string} = {}
    if preview[1] ~= nil then 
            add(out, attacker.character.name .." -> ".. defender.character.name)
            add(out, "Hit: "..preview[1].hit_chance.."%")
            add(out, "Dmg: "..preview[1].dmg)
    else
        add(out, "No attack!")
        add(out, "")
        add(out, "")
        
    end
    if preview[2] ~= nil then
        add(out, attacker.character.name .." <- ".. defender.character.name)
        add(out, "Hit: "..preview[2].hit_chance.."%")
        add(out, "Dmg: "..preview[2].dmg)
    else
        add(out, "No counterattack!")
        add(out, "")
        add(out, "")
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

return CombatPreview
