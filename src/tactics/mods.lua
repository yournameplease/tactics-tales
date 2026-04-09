---@brief
--- Defines the data structures for mod specifications.

---@alias ModId string

---@class ModContent
---@field maps string Path to maps data file (without .lua extension).
---@field battles string Path to battles data file.
---@field stories string Path to stories data file.
---@field characters string Path to characters data file.
---@field items string Path to items data file.

---@class ModSpec
---@field id ModId
---@field name string
---@field version string
---@field dependendcies ModId[] List of mod IDs this mod depends on.
---@field content ModContent

local mods = {}

return mods
