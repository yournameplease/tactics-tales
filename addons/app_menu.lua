--- @meta

--- @class __MenuItem
--- @field id? integer Unique identifier, used to sort items (otherwise order added is used)
--- @field label? string | function User facing label
--- @field shortcut? string Drawn right justified in the menu
--- @field greyed? boolean Greyed out item (use for ---)
--- @field action? function Callback on select -- param b is the button pressed (left or right)
--- @field divider? boolean Is item a divider
local __MenuItem = {}

--- Adds a menu item
--- If m is nil, reset the menu
--- View implementation in /system/lib/app_menu.lua
--- @param m? __MenuItem
function menuitem(m) end

--- Adds a menu item
--- id is the numerical id
--- label is the label for the menu item
--- action is a callback for when the item is pressed -- param b is the button pressed (left or right)
--- View implementation in /system/lib/app_menu.lua
--- @param id integer
--- @param label string | function
--- @param action function
function menuitem(id, label, action) end
