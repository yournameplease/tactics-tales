require("src/tactics/types")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/ui/box")
local CharacterRenderer = require("src/tactics/character/character_renderer")
local Colors = require("src/tactics/colors")
local Draw = require("src/tactics/draw")

global record PortraitBox
    is UIElement
    get_selected_unit: function(UIContextManager): BattleUnit
end

setmetatable(PortraitBox, { __index = Box })

local FEET_ANCHOR = Point.of(11, 22)

function PortraitBox.new(get_selected_unit: function(UIContextManager): BattleUnit): PortraitBox
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

function PortraitBox:draw(state: UIContextManager, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local unit = self.get_selected_unit(state)
    if unit then
        local shadow_color = ui_theme.COLOR_DECORATION_SHADOW
        Draw.draw_shadow(shadow_color,
                function(draw_x: integer,draw_y: integer)
                    local draw_pos: Point = DrawPoint.of(draw_x, draw_y)
                    CharacterRenderer.draw(unit, (FEET_ANCHOR+draw_pos) as DrawPoint, unit.side, false, false)
                end,
                self.x, self.y)

        Colors.apply_palette("paper")
        local self_pos: Point = DrawPoint.of(self.x, self.y)
        CharacterRenderer.draw(unit, (FEET_ANCHOR+self_pos) as DrawPoint, unit.side, false, false)
        pt.reset_pal()
    end
end

return PortraitBox
