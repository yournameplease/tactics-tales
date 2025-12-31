require("src/tactics/systems/service")
require("src/tactics/ui/types")

require("src/tactics/story/story_page")
require("src/tactics/config")
local box = require("src/tactics/ui/box")

local SplitPages = require("src/tactics/ui/panels/split_pages")
local story_page_panel = require("src/tactics/ui/panels/story_page")

require("src/tactics/ui/validator")

local left = box.new({ dir="col", flex_grow = 1, padding = 2})

local story_page = story_page_panel.new({
    dir="col",
    flex_grow = 1,
    padding = 2,
})

local root = SplitPages.new(left, story_page)

return { root = root }
