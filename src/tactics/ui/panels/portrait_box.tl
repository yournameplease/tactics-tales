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

local character = {}

local FEET_ANCHOR = point.of(9, 20)

local function draw_portrait(
    get_selected_unit: function(UIContextManager): DrawableCharacterInstance,
    palette: Colors.PaletteId
): function(self: box.UIElement, state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    return function(self: box.UIElement, state: UIContextManager, draw_target_manager: DrawTargetManager, _ui_theme: UITheme)
        local unit = get_selected_unit(state)
        if unit then
            local self_pos: Point = point.of(self.rect.c_x, self.rect.c_y)
            CharacterRenderer.draw(
                unit,
                (FEET_ANCHOR+self_pos) as Point,
                draw_target_manager,
                palette or true,
                false,
                true,
                nil
            )
            pt.reset_pal()
        end
    end
end

function character.portrait_box(
    get_selected_unit: function(UIContextManager): DrawableCharacterInstance,
    palette: Colors.PaletteId
): box.UIElement
    return box.builder("portrait_box")
        :layout{
            width = 24,
            height = 28,
            padding = box.layout.padding(4),
        }
        :style{
            decoration_padding = 3,
            decoration = 'border'
        }
        :on_draw(draw_portrait(get_selected_unit, palette))
        :build()
end

return character
