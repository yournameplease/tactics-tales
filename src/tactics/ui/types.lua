---@brief
--- Contains basic UI-related type definitions, such as UILayoutId.
---
--- UILayoutId is intentionally generic at the engine layer. Games define
--- a narrowed alias enumerating their specific screens (e.g. TacticsLayoutId
--- in src/tactics/ui/layout/types.lua) and use that at game-specific
--- consumers.

---@alias UILayoutId string

return {}
