require("src/tactics/systems/service")
require("src/tactics/ui/types")

require("src/tactics/story/story_menu_context")
require("src/tactics/config")

require("src/tactics/ui/panels/tactics_map")
local box = require("src/tactics/ui/box")
local text_node = require("src/tactics/ui/components/text_node")
require("src/tactics/ui/panels/unit_info")
require("src/tactics/ui/panels/combat_preview")
require("src/tactics/ui/panels/event_message_log")
local book_box = require("src/tactics/ui/decoration/book_box")


require("src/tactics/ui/validator")


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
