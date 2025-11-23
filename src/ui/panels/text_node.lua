Box = include "src/ui/box.lua"

local TextNode = {}

local TEXT_HEIGHT = 8

function TextNode.new(text_getter, rows, props)
    local box = Box.new(props)
    setmetatable(box, { __index = TextNode })

    box.padding = props.padding or 0
    box.decoration_padding = 0
    box.text_getter = text_getter
    box.h = rows * (TEXT_HEIGHT + 2)
    box.justify = props.justify or "left"  -- "left", "right", "center"

    return box
end

function TextNode:draw(state)
    Box.draw(self, state)

    local text = self.text_getter(state)

    local text_width = print(text, 0, -1000)

    local t_x
    if self.justify == "left" then
        t_x = self.x + self.padding + 1
    elseif self.justify == "center" then
        t_x = self.x + (self.w - 2 * (self.padding + 1) - text_width) / 2
    elseif self.justify == "right" then
        t_x = self.x + self.w - self.padding - 1 - text_width - 1
    else
        error("Unexpected value!")
    end

        print(text, t_x, self.y + self.padding + 1, UI_MANAGER.THEME.COLOR_INTERIOR_TEXT)
    end

setmetatable(TextNode, { __index = Box})

return TextNode