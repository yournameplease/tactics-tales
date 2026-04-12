---@brief
--- Contains generic drawing utility functions, like drawing a shadow.

--- Draw a shadow behind a shape by rendering it in color `c` in all four cardinal directions.
---@param c integer Shadow color index.
---@param draw fun(x: number, y: number) Drawing function to call for each shadow offset.
---@param x number
---@param y number
local function draw_shadow(c, draw, x, y)
    for i = 1, 31 do
        pal(i, c)
    end
    draw(x - 1, y)
    draw(x, y - 1)
    draw(x + 1, y)
    draw(x, y + 1)
    pal()
end

return {
    draw_shadow = draw_shadow
}
