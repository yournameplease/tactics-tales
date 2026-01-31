local box = require("src.tactics.ui.box")
local split_pages = require("src.tactics.ui.panels.split_pages")
local story_page_panel = require("src.tactics.ui.panels.story_page")

local left = box.new({ dir="col", flex_grow = 1, padding = 2})

local story_page = story_page_panel.new({
    dir="col",
    flex_grow = 1,
    padding = 2,
})

local root = split_pages.new(left, story_page)

return { root = root }
