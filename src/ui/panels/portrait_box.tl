require("src/types")
require("src/ui/box")
local CharacterRenderer = require("src/character/character_renderer")
local Colors = require("src/colors")

global record PortraitBox
    is UIElement
    get_selected_unit: function(GameContext): BattleUnit
end

setmetatable(PortraitBox, { __index = Box })

local FEET_ANCHOR = AnimationAnchorPoint.of(12, 22)

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
        Colors.apply_palette("paper")
        local self_pos: Point = DrawPoint.of(self.x, self.y)
        CharacterRenderer.draw(unit, (FEET_ANCHOR+self_pos) as DrawPoint, unit.side, false, false)
        pal()
    end
end

return PortraitBox
