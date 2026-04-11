---@brief
--- Defines the UI layout for a story page.

local book = require("src.tactics.ui.decoration.book")
local story_page = require("src.tactics.ui.panels.story_page")
local box = require("src.tactics.ui.box")
local control_hints = require("src.tactics.ui.panels.control_hints")

local left = book.flex_page()
left:add(box.spacer(1))
left:add(control_hints.new(
    ---@param s UIContextManager
    function(s)
        return s.story_context.menu_manager.menu_step
    end,
    {
        ["BUTTON_A"] = "Advance",
    }
))

local right = book.flex_page()
right:add(story_page.new())

local root = book.split_pages(left, right)

return { root = root }
