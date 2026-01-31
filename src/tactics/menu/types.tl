local point = require("src.tactics.util.point")
local Point = point.Point

local type MenuId = string
local type MenuStep = string

local record MenuState
    step: MenuStep
    menu_id: MenuId
    point: Point
end

local menu_types = {
    MenuId = MenuId,
    MenuStep = MenuStep,
    MenuState = MenuState,
}

return menu_types
