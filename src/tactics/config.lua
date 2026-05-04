---@brief
--- Defines the static configuration values used throughout the application.

---@class StaticConfig
---@field SCREEN_WIDTH integer
---@field SCREEN_HEIGHT integer
---@field VIEWPORT_WIDTH integer
---@field VIEWPORT_HEIGHT integer
---@field TILE_WIDTH integer
---@field TILE_HEIGHT integer
---@field WALL_HEIGHT integer
---@field CAMERA_DEAD_ZONE_PLAYER integer
---@field CAMERA_DEAD_ZONE_ENEMY integer
---@field CAMERA_EDGE_SCROLL_BORDER integer
---@field CAMERA_EDGE_SCROLL_SPEED integer
---@field PHASE_BANNER_DURATION integer
---@field MOD_GFX_SLOT_START integer First spritesheet slot reserved for mod GFX.
---@field MOD_GFX_SLOT_END integer Last spritesheet slot reserved for mod GFX.

---@type StaticConfig
STATIC_CONFIG = {
    SCREEN_WIDTH = 480,
    SCREEN_HEIGHT = 270,
    -- note: viewport and tile width/heigh probably belong in a per-campaign or per-map config
    VIEWPORT_WIDTH = 20,
    VIEWPORT_HEIGHT = 16,
    TILE_WIDTH = 16,
    TILE_HEIGHT = 16,
    WALL_HEIGHT = 16,
    CAMERA_DEAD_ZONE_PLAYER = 2,
    CAMERA_DEAD_ZONE_ENEMY = 6,
    CAMERA_EDGE_SCROLL_BORDER = 16,
    CAMERA_EDGE_SCROLL_SPEED = 1,
    PHASE_BANNER_DURATION = 90,
    MOD_GFX_SLOT_START = 16,
    MOD_GFX_SLOT_END = 31,
}
