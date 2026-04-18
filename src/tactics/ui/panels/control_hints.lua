---@brief
--- A UI panel that displays contextual control hints (e.g., "Select", "Back").

local box = require("src.tactics.ui.box")

local control_hints = {}

---@alias DefaultHints table<InputAction, string>

---@type table<InputAction, integer> Sprite sheet offset per input action.
local SPRITE_OFFSETS = {
    ["BUTTON_A"] = 0,
    ["BUTTON_B"] = 1,
    ["SHOULDER_L"] = 4,
    ["SHOULDER_R"] = 5,
}

---@type table<InputAction, boolean> Whether a mouse sprite exists for this action.
local HAS_MOUSE_SPRITE = {
    ["BUTTON_A"] = true,
    ["BUTTON_B"] = true,
    ["SHOULDER_L"] = false,
    ["SHOULDER_R"] = false,
}

local BASE_MOUSE_SPRITE = 16

---@type table<string, integer> Base sprite index per glyph family.
local BASE_JOYPAD_SPRITES = {
    ["keyboard"] = 24,
    ["picotron"] = 32,
    ["snes"] = 40,
    ["nintendo"] = 48,
    ["xbox"] = 56,
    ["playstation"] = 64,
}

--- Return the sprite index for the given input action and method.
---@param input_label string InputAction key (e.g. "BUTTON_A")
---@param input_method string InputMethod ("mouse" or "joypad")
---@return integer
local function sprite_by_label_and_method(input_label, input_method)
    local base_sprite
    if input_method == "mouse" then
        base_sprite = BASE_MOUSE_SPRITE
    else
        base_sprite = BASE_JOYPAD_SPRITES[DYNAMIC_CONFIG.glyph_family]
    end
    return base_sprite + SPRITE_OFFSETS[input_label]
end


---
---@param input_label InputAction
---@return boolean draw_mouse
---@return boolean draw_joy
local function allow_inputs_for_label(input_label)
    local allow_draw_mouse = true
    local allow_draw_joy = true
    if DYNAMIC_CONFIG then
        allow_draw_joy = DYNAMIC_CONFIG.input_group == "mouse_and_keyboard"
            or DYNAMIC_CONFIG.input_group == "joy_only"
        allow_draw_mouse = DYNAMIC_CONFIG.input_group == "mouse_and_keyboard"
                or DYNAMIC_CONFIG.input_group == "mouse_only"
    end

    local draw_mouse = HAS_MOUSE_SPRITE[input_label] and allow_draw_mouse
    local draw_joy = allow_draw_joy

    return draw_mouse, draw_joy
end


--- Build a row of glyphs (mouse + joypad sprites) for the given input action.
---@param input_label InputAction key
---@param text_color string? UITextColor for the separator text
---@return UIElement
local function control_hint_glyphs(input_label, text_color)
    local row = box.builder("control_row_" .. input_label)
        :direction("row")
        :container("modal")
        :build()

    local draw_mouse, draw_joy = allow_inputs_for_label(input_label)

    if draw_mouse then
        row:add(
            box.builder("control_sprite_" .. input_label)
            :sprite{ ox = 1, oy = 1 }
            :layout{ width = 9, height = 9 }
            :on_update(function(self, _state)
                self.sprite.s = sprite_by_label_and_method(input_label, "mouse")
            end)
            :build())
    end
    if draw_mouse and draw_joy then
        row:add(
            box.builder("control_text_" .. input_label)
            :layout{
                width = 6,
                height = 10,
                padding = box.layout.padding(2),
            }
            :text{
                content = { "/" },
                draw_properties = { wrap = "no_wrap" },
                text_color = text_color,
            }
            :build())
    end
    if draw_joy then
        row:add(
            box.builder("control_sprite_" .. input_label)
            :sprite{ ox = 1, oy = 1 }
            :layout{ width = 9, height = 9 }
            :on_update(function(self, _state)
                self.sprite.s = sprite_by_label_and_method(input_label, "joypad")
            end)
            :build())
    end

    return row
end

--- Build a full control hint row with glyphs and a dynamic text label.
---@param input_label string InputAction key
---@param menu_step_func fun(state: UIContextManager): ActiveMenuStep? Function returning the current menu step.
---@param default_hints DefaultHints Fallback hints when no menu step is active.
---@return UIElement
local function control_hint_row(input_label, menu_step_func, default_hints)
    local row = box.builder("control_row_" .. input_label)
        :direction("row")
        :container("strip")
        :build()

    row:add(control_hint_glyphs(input_label, nil))
    row:add(
        box.builder("control_text_" .. input_label)
        :text{ draw_properties = { wrap = "no_wrap" } }
        :layout{
            flex_grow = 1,
            padding = box.layout.padding(1),
        }
        :on_update(function(self, state)
            local menu_step = menu_step_func(state)

            if menu_step ~= nil and menu_step.menu_actions ~= nil then
                self.text.content = {
                    menu_step.menu_actions[input_label]
                    and " " .. menu_step.menu_actions[input_label].description
                    or nil
                }
                return
            end

            if default_hints ~= nil then
                self.text.content = {
                    default_hints[input_label]
                    and " " .. default_hints[input_label]
                    or nil
                }
                return
            end
        end)
        :build())

    return row
end


---@param input_label string InputAction key
---@param message string Label text to display beside the glyph.
---@param text_color string? UITextColor for glyph and label text.
---@return fun(ctx: UIContextManager): UIElement[]
function generate_centered_control_hint_row(input_label, message, text_color)
    return function(_)
        local row = box.builder("control_row_" .. input_label)
            :direction("row")
            :container("strip")
            :build()

        row:add(box.spacer(1))
        row:add(control_hint_glyphs(input_label, text_color))
        row:add(
            box.builder("control_text_" .. input_label)
            :direction("col")
            :container("strip")
            :padding(1)
            :text{
                content = { " " .. message },
                draw_properties = { wrap = "no_wrap" },
                text_color = text_color,
            }
            :build())
        row:add(box.spacer(1))
    
        return {row}
    end
end

--- Build a centered control hint row with a fixed message and optional text color.
---@param input_label string InputAction key
---@param message string Label text to display beside the glyph.
---@param text_color string? UITextColor for glyph and label text.
---@return UIElement
function control_hints.centered_control_hint_row(input_label, message, text_color)
    local self = box.builder("control_hints")
        :direction("col")
        :container("block")
        :child_generator{
            current_key = function(_)
                return DYNAMIC_CONFIG and DYNAMIC_CONFIG.input_group
            end,
            generate_children = generate_centered_control_hint_row(input_label, message, text_color)
        }
        :build()

    return self
end

---@param menu_step_func fun(state: UIContextManager): ActiveMenuStep? Function returning the current menu step.
---@param default_hints DefaultHints Fallback hints when no menu step is active.
---@return fun(ctx: UIContextManager): UIElement[]
function control_hint_rows(menu_step_func, default_hints)
    return function(_)
        children = {}

        if DYNAMIC_CONFIG.input_group == "mouse_only" then
            table.insert(children, control_hint_row("BUTTON_A", menu_step_func, default_hints))
            table.insert(children, control_hint_row("BUTTON_B", menu_step_func, default_hints))
        else
            table.insert(children, control_hint_row("BUTTON_A", menu_step_func, default_hints))
            table.insert(children, control_hint_row("BUTTON_B", menu_step_func, default_hints))
            table.insert(children, control_hint_row("SHOULDER_L", menu_step_func, default_hints))
            table.insert(children, control_hint_row("SHOULDER_R", menu_step_func, default_hints))
        end
    
        return children
    end
end

--- Build a control hints panel showing hints for all four input actions.
---@param menu_step_func fun(state: UIContextManager): ActiveMenuStep? Function returning the current menu step.
---@param default_hints DefaultHints Fallback hints when no menu step is active.
---@return UIElement
function control_hints.new(menu_step_func, default_hints)
    local self = box.builder("control_hints")
        :direction("col")
        :container("block")
        :child_generator{
            current_key = function(_)
                return DYNAMIC_CONFIG and DYNAMIC_CONFIG.input_group
            end,
            generate_children = control_hint_rows(menu_step_func, default_hints)
        }
        :build()

    return self
end

return control_hints
