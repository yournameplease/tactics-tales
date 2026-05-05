---@brief
--- A UI panel for displaying a character's portrait.

local point = require("src.tactics.util.point")
local box = require("src.tactics.ui.box")
local CharacterRenderer = require("src.tactics.character.character_renderer")

local character = {}

local FEET_ANCHOR = point.of(7, 18)

--- Build a draw function that renders the selected unit's portrait.
---@param get_selected_unit fun(state: UIContextManager): DrawableCharacterInstance
---@param palette PaletteId
---@return fun(self: UIElement, state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
local function draw_portrait(get_selected_unit, palette)
    return function(self, state, draw_target_manager, _ui_theme)
        local unit = get_selected_unit(state)
        if unit then
            local self_pos = point.of(self.rect.c_x, self.rect.c_y)
            CharacterRenderer.draw(
                unit,
                FEET_ANCHOR + self_pos,
                draw_target_manager,
                palette or true,
                false,
                true,
                nil
            )
            pal()
        end
    end
end

--- Return a UI element that displays the selected unit's portrait.
---@param get_selected_unit fun(state: UIContextManager): DrawableCharacterInstance
---@param palette PaletteId
---@return UIElement
function character.portrait_box(get_selected_unit, palette)
    return box.builder("portrait_box")
        :layout {
            width = 24,
            height = 28,
            padding = box.layout.padding(4),
        }
        :style {
            decoration_padding = 3,
            decoration = 'border'
        }
        :on_draw(draw_portrait(get_selected_unit, palette))
        :build()
end

return character
