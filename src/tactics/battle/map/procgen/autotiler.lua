---@brief
--- Glyph-grid → BattleMap autotiler: steps 12–14 of the procgen pipeline.
--- Writes tile id 1 (floor) for passable glyphs and tile id 2 (wall) for '#'
--- into the ground layer, and collects spawn glyph positions into tile_labels.

local battle_map = require("src.tactics.battle.battle_map")
local point      = require("src.tactics.util.point")

local autotiler = {}

-- Glyphs that produce a tile label → label name mapping.
local SPAWN_LABELS = {
    d = "player_deployment",
    i = "enemy_infantry",
    r = "enemy_ranged",
    t = "enemy_tank",
    c = "enemy_commander",
    g = "enemy_tank",
    I = "enemy_infantry_boss",
    R = "enemy_ranged_boss",
    T = "enemy_tank_boss",
    G = "enemy_tank_boss",
    C = "enemy_commander_boss",
}

-- All glyphs that map to floor (tile id 1).
local FLOOR_GLYPHS = {
    ["."] = true, d = true, i = true, r = true,
    t = true, c = true, p = true, a = true, g = true,
    I = true, R = true, T = true, G = true, C = true,
}

-- Metadata for each spawn label: base role and optional tags.
local SPAWN_LABEL_META = {
    player_deployment  = { role = "player" },
    enemy_infantry     = { role = "enemy_infantry" },
    enemy_ranged       = { role = "enemy_ranged" },
    enemy_tank         = { role = "enemy_tank" },
    enemy_commander    = { role = "enemy_commander" },
    enemy_infantry_boss  = { role = "enemy_infantry",  tags = { "boss" } },
    enemy_ranged_boss    = { role = "enemy_ranged",    tags = { "boss" } },
    enemy_tank_boss      = { role = "enemy_tank",      tags = { "boss" } },
    enemy_commander_boss = { role = "enemy_commander", tags = { "boss" } },
}

--- Convert a 16×16 glyph grid into a BattleMap.
--- The grid is a 1-indexed array of 16 strings each of length 16.
--- x and y in the returned BattleMap are 0-indexed.
---@param rows string[]  16-element array of 16-character strings
---@param base_tile_id integer?  Sprite base offset added to all tile writes (default 0).
---@return BattleMap
function autotiler.build(rows, base_tile_id)
    base_tile_id = base_tile_id or 0
    local ground = userdata("i16", 16, 16)
    local tile_labels = {}

    for gy = 1, 16 do
        local row = rows[gy]
        for gx = 1, 16 do
            local ch  = row:sub(gx, gx)
            local bx  = gx - 1  -- 0-indexed map coordinate
            local by  = gy - 1

            ground:set(bx, by, (FLOOR_GLYPHS[ch] and 1 or 2) + base_tile_id)

            local label = SPAWN_LABELS[ch]
            if label then
                if not tile_labels[label] then
                    tile_labels[label] = {}
                end
                table.insert(tile_labels[label], point.of(bx, by))
            end
        end
    end

    local spawn_label_meta = {}
    for label in pairs(tile_labels) do
        if SPAWN_LABEL_META[label] then
            spawn_label_meta[label] = SPAWN_LABEL_META[label]
        end
    end

    local map = battle_map.new(16, 16, tile_labels)
    map.layers = { terrain = { ground = ground } }
    map.base_tile_id = base_tile_id
    map.spawn_groups = {}
    map.rect_zones   = {}
    map.spawn_label_meta = spawn_label_meta
    return map
end

return autotiler
