require("src/ui/box")
local CharacterRenderer = require("src/character/character_renderer")

global record PortraitBox
    is UIElement
    get_selected_unit: function(GameContext): BattleUnit
end

setmetatable(PortraitBox, { __index = Box })

local BACKGROUND_SPRITE = 7 + 3 * 256

function PortraitBox.new(get_selected_unit: function(GameContext): BattleUnit): PortraitBox
    local box = Box.new({
        w=24, h=28,
        padding = 4,
        decoration_padding = 3,
        decoration = 'border'
    }) as PortraitBox
    setmetatable(box, {__index = PortraitBox})
    box.get_selected_unit = get_selected_unit
    return box
end

function PortraitBox:draw(state: GameContext, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local unit = self.get_selected_unit(state)
    if unit then
        -- TODO: magic numbers galore
        spr(BACKGROUND_SPRITE, self.x, self.y+8)
        -- Use the renderer we defined previously
        CharacterRenderer.draw(unit, { x = self.x+8, y = self.y+28}, unit.side, true, false)
    end
end

return PortraitBox
