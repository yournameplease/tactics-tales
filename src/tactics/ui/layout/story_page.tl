---@brief
--- Defines the UI layout for a story page.

local book = require("src.tactics.ui.decoration.book")
local story_page = require("src.tactics.ui.panels.story_page")

local left = book.flex_page()
local right = book.flex_page()
right:add(story_page.new())

local root = book.split_pages(left, right)

return { root = root }
