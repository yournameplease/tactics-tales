---@brief
--- Defines the UI layout for the title screen.

local box = require("src.tactics.ui.box")
local book = require("src.tactics.ui.decoration.book")
local control_hints = require("src.tactics.ui.panels.control_hints")

local root = box.builder("title_screen")
    :layout{
        dir = "col",
        width = 480,
        height = 270,
    }
    :style{
        solid = true,
    }
    :build()

-- Left Sidebar

root:add(box.spacer(1))
local row = root:add(
    box.builder("title_screen_row")
        :direction("row")
        :container("strip")
        :build()
)
root:add(box.spacer(1))

local left = box.spacer(1)
left:add(box.spacer(1))

row:add(left)
local book_box = row:add(book.book_box(150, 200, 15))
row:add(box.spacer(1))

book_box:add(box.spacer(1))

local title_row = box.builder("title_row")
    :direction("row")
    :container("strip")
    :build()
title_row:add(box.spacer(1))
title_row:add(box.builder("title_text")
    :layout{
        height = 32,
        width = 64,
    }
    :sprite{
        s = 5,
    }
    :build())
title_row:add(box.spacer(1))

book_box:add(title_row)

book_box:add(box.spacer(2))
book_box:add(control_hints.centered_control_hint_row(
    "BUTTON_A",
    "Start",
    "trim"
))
book_box:add(box.spacer(1))

return { root = root }
