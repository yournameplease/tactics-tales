---@brief
--- Contains generic drawing utility functions, like drawing a shadow.

local function draw_shadow(c: integer, draw: function(x: number, y: number), x: number, y: number)
    for i=1,31 do
        pt.set_pal(i, c)
    end
    draw(x-1, y)
    draw(x, y-1)
    draw(x+1, y)
    draw(x, y+1)
    pt.reset_pal()
end

return {
    draw_shadow = draw_shadow
}
