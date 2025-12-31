local box = require("src/tactics/ui/box")
local text_node = require("src/tactics/ui/components/text_node")
local book_box = require("src/tactics/ui/decoration/book_box")

local root = box.new({
    x=0, y=0,
    w=480, h=270,
    -- internal_margin = {t = 4},
    dir="col",
    padding = 0,
    gap = 0,
    -- transparent = true
})

-- Left Sidebar

root:add(box.spacer(1))
local row = root:add(box.flex_row())
root:add(box.spacer(1))
row:add(box.spacer(1))
local book = row:add(book_box.new(150,200,15))
row:add(box.spacer(1))

book:add(box.spacer(1))
book:add(text_node.new( { text = {"Tactics Tales"}, flex_grow = 1, draw_properties = {justify='center', wrap='no_wrap'}, text_color = "trim" } ))
book:add(box.spacer(3))

return { root = root }
