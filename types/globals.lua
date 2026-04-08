---@meta
---@diagnostic disable missing-fields
--- Game-specific globals for Tactics Tales.
--- These are injected at runtime by main.tl / picotron_shim.tl.

---@alias LogLevel "ERROR"|"WARN"|"INFO"|"DEBUG"|"TRACE"
---@alias Angle number
---@alias Color integer
---@alias Path string
---@alias CardinalDirection "up"|"down"|"left"|"right"
---@alias DialogueSpeed "very_slow"|"slow"|"normal"|"fast"|"very_fast"|"instant"
---@alias GlyphFamily "keyboard"|"picotron"|"snes"|"nintendo"|"xbox"|"playstation"

---@class Logger
---@field error fun(...: any)
---@field warn fun(...: any)
---@field info fun(...: any)
---@field debug fun(...: any)
---@field trace fun(...: any)

---@class DynamicConfig
---@field log_level LogLevel
---@field draw_flexbox_debug boolean
---@field draw_target_debug boolean
---@field profile? boolean
---@field head_scale integer
---@field dialogue_speed DialogueSpeed
---@field glyph_family? GlyphFamily

---@class StaticConfig
---@field SCREEN_WIDTH integer
---@field SCREEN_HEIGHT integer
---@field MAP_WIDTH integer
---@field MAP_HEIGHT integer
---@field TILE_WIDTH integer
---@field TILE_HEIGHT integer
---@field WALL_HEIGHT integer

--- Logger injected by debug.tl.
---@type Logger
log = {}

--- Global runtime configuration (mutable).
---@type DynamicConfig
DYNAMIC_CONFIG = {}

--- Global static configuration (read-only after init).
---@type StaticConfig
STATIC_CONFIG = {}

--- Data path prefix for asset loading.
---@type string
DATP = ""

--- Shared library table exposed to mods.
---@type {[string]: any}
lib = {}

--- Raises an error for unimplemented code paths.
---@param message? string
---@return any
function todo(message) end

--- Raises an error for unexpected state values.
---@param state string
function unexpected(state) end
