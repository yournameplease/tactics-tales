---@brief
--- Contains basic type definitions for the menu system.

---@alias MenuId string
---@alias MenuHandlerId string Identifies a handler function registered to respond to menu commands.
---@alias MenuStep string Identifies a named step within a menu flow.

---@class MenuState
---@field step? MenuStep The current active step in the menu flow.
---@field menu_id? MenuId The menu this state belongs to.
local MenuState = {}

---@alias MenuCommand "select"|"select_alt"|"menu"|"back"|"increment_selection"|"decrement_selection"|"cycle_left"|"cycle_right"

---@class MenuAction
---@field command MenuCommand The abstract menu command this action represents.
---@field description? string Human-readable description shown in control hints.
local MenuAction = {}

---@alias MenuActions table<InputAction, MenuAction> Maps physical input buttons to their corresponding menu actions.

return {
    MenuState = MenuState,
    MenuAction = MenuAction,
}
