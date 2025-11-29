require("src/ui/box")
require("src/ui/panels/text_node")
require("src/ui/panels/portrait_box")

global record UnitInfo
    is UIElement
end

setmetatable(UnitInfo, { __index = Box })

function UnitInfo.new(props: UnitInfo): UnitInfo
    props.dir = "row"
    props.gap = props.gap or 4
    props.padding = props.padding or 4
    props.auto_height = props.auto_height or true

    local self = Box.new(props) as UnitInfo
    setmetatable(self, { __index = UnitInfo })

    self:add(PortraitBox.new(function(state: GameContext): BattleUnit return state.hovered_unit end))

    local info_col = self:add(Box.new({
        auto_height = true,
        dir = "col",
        gap = 2
    }))

    -- ROW 1: Name and Level
    info_col:add(TextNode.new({
        func = function(state: GameContext): {string}
            local u = state.hovered_unit
            if not u then return { "No Unit Selected" } end
            return { u.character.name .. " Lv." .. 1 }
        end
    }))

    -- ROW 2-4: HP, Weapon
    info_col:add(TextNode.new({
        rows = 3,
        func = function(state: GameContext): {string}
            local u = state.hovered_unit
            if not u then return { "", "", "" } end

            local w = u.weapon

            return {
                "HP: " .. u.hp_current .. "/" .. u.character.stats.hp_max,
                w and w.name or "Unarmed",
                w and ("(" .. w.accuracy .. "% for " .. w.damage .. " dmg)") or "",
            }
        end
    }))

    return self
end

return UnitInfo
