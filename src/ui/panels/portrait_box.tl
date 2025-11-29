require("src/ui/box")

global record PortraitBox
    is UIElement
    get_selected_unit: function(GameContext): BattleUnit
end

setmetatable(PortraitBox, { __index = Box })

local BACKGROUND_SPRITE = 7 + 3 * 256

function PortraitBox.new(get_selected_unit: function(GameContext): BattleUnit): PortraitBox
    local box = Box.new({ w=20, h=24 }) as PortraitBox
    setmetatable(box, {__index = PortraitBox})
    box.get_selected_unit = get_selected_unit
    return box
end

function PortraitBox:draw(state: GameContext, ui_theme: UITheme)
    self:draw(state, ui_theme)

    local unit = self.get_selected_unit(state)
    if unit then
        -- TODO: magic numbers galore
        spr(BACKGROUND_SPRITE, self.x, self.y+8)
        -- Use the renderer we defined previously
        unit.character:draw({ x = self.x+2, y = self.y+12}, unit.side, true, false)
    end
end

return PortraitBox
