---@brief
--- A UI panel for displaying a character's portrait.

local point = require("src.tactics.util.point")
local Point = point.Point
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local box = require("src.tactics.ui.box")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local CharacterRenderer = require("src.tactics.character.character_renderer")
local Colors = require("src.tactics.colors")
local DrawableCharacterInstance = require("src.tactics.character.object.character").DrawableCharacterInstance

local record PortraitBox
    is box.UIElement
    get_selected_unit: function(UIContextManager): DrawableCharacterInstance
    palette: Colors.PaletteId
end
setmetatable(PortraitBox, { __index = box.Box })

local portrait_box = {}

local FEET_ANCHOR = point.of(11, 22)

function portrait_box.new(
    get_selected_unit: function(UIContextManager): DrawableCharacterInstance,
    palette: Colors.PaletteId
): box.UIElement
    local self = box.new({
        w=24, h=28,
        padding = 4,
        decoration_padding = 3,
        decoration = 'border'
    }) as PortraitBox
    setmetatable(self, {__index = PortraitBox})
    self.get_selected_unit = get_selected_unit
    self.palette = palette
    return self
end

function PortraitBox:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    box.Box._draw(self, state, draw_target_manager, ui_theme)

    local unit = self.get_selected_unit(state)
    if unit then
        local self_pos: Point = point.of(self.x, self.y)
        CharacterRenderer.draw(
            unit,
            (FEET_ANCHOR+self_pos) as Point,
            draw_target_manager,
            self.palette or true,
            false,
            true,
            nil
        )
        pt.reset_pal()
    end
end

return portrait_box
