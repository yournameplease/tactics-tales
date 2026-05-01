---@brief
--- Defines the core UIContext interface, which provides UI-related
--- state to the rendering system.

require("src.tactics.ui.types")

---@alias UIContextType "battle"|"campaign"|"game"

---@class UIContext
---@field type UIContextType
---@field layout UILayoutId

return {}
