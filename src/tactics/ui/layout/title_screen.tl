---@brief
--- Defines the UI layout for the title screen.

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local book = require("src.tactics.ui.decoration.book")

local root = box.builder("title_screen")
:layout{
    dir="col",
    width = 480,
    height = 270,
}
:build()

-- Left Sidebar

root:add(box.spacer(1))
local row = root:add(
    box.builder("title_screen_row")
    :layout(box.layout.row_fill())
    :build()
)
root:add(box.spacer(1))
row:add(box.spacer(1))
local book_box = row:add(book.book_box(150,200,15))
row:add(box.spacer(1))

book_box:add(box.spacer(1))
book_box:add(box.builder("title_text")
    :text{
        content = {"Tactics Tales"},
        draw_properties = {
            justify='center',
            wrap='no_wrap'
        },
        text_color = "trim"
    }
    :build())
book_box:add(box.spacer(3))

return { root = root }
