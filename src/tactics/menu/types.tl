---@brief
--- Contains basic type definitions for the menu system.

local type MenuId = string
local type MenuHandlerId = string
local type MenuStep = string

local record MenuState
    step: MenuStep
    menu_id: MenuId
end

local enum MenuCommand
    "select"
    "select_alt"
    "menu"
    "back"
    "increment_selection"
    "decrement_selection"
    "cycle_left"
    "cycle_right"
end

local record MenuAction
	command: MenuCommand
	description: string
end

local menu_types = {
    MenuId = MenuId,
    MenuHandlerId = MenuHandlerId,
    MenuStep = MenuStep,
    MenuState = MenuState,
    MenuCommand = MenuCommand,
    MenuAction = MenuAction,
}

return menu_types
