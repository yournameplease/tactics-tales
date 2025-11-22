

function draw_shadow(c, draw, x, y)
    for i=1,31 do
        pal(i, c)
    end
    draw(x-1, y)
    draw(x, y-1)
    draw(x+1, y)
    draw(x, y+1)
    pal()
end