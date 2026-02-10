---@brief
--- Contains basic type definitions for the menu system.

local type MenuId = string
local type MenuStep = string

local record MenuState
    step: MenuStep
    menu_id: MenuId
end

local menu_types = {
    MenuId = MenuId,
    MenuStep = MenuStep,
    MenuState = MenuState,
}

return menu_types
