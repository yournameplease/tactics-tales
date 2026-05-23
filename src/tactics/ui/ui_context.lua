---@brief
--- Defines the core UIContext interface, which provides UI-related
--- state to the rendering system.
---
--- UIContext is the engine-side interface: each implementation tags
--- itself with a string `type` (used as a key in UIContextStack) and
--- provides an `enrich` method called once per frame to refresh
--- derived fields.

require("src.tactics.ui.types")

---@alias UIContextType string

---@class UIContext
---@field type string
---@field layout UILayoutId
---@field enrich fun(self: UIContext)

return {}
