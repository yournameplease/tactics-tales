require("src/tactics/types")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
local CharacterRenderer = require("src/tactics/character/character_renderer")
local Colors = require("src/tactics/colors")

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

function PortraitBox:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    Box._draw(self, state, draw_target_manager, ui_theme)

    local unit = self.get_selected_unit(state)
    if unit then
        Colors.apply_palette("paper")
        local self_pos: Point = Point.of(self.x, self.y)
        CharacterRenderer.draw(unit, (FEET_ANCHOR+self_pos) as Point, draw_target_manager, false, false, true)
        pt.reset_pal()
    end
end

return PortraitBox
