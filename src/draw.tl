local draw_util = {}

global function draw_shadow(c: integer, draw: function(x: number, y: number), x: number, y: number)
    for i=1,31 do
        pal(i, c)
    end
    draw(x-1, y)
    draw(x, y-1)
    draw(x+1, y)
    draw(x, y+1)
    pal()
end

return draw_util