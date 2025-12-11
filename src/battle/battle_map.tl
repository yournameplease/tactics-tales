require("src/types")

global record TerrainData
    movement_cost: integer
    dodge: integer
end

local TERRAIN_DATA: { integer: TerrainData } = {
    [0] = {
        movement_cost = 1,
        dodge = 0
    },
    [1] = {
        movement_cost = 2,
        dodge = 0
    },
    [2] = {
        movement_cost = 2,
        dodge = 0
    },
    [3] = {
        movement_cost = 3,
        dodge = 0
    },
    [4] = {
        movement_cost = 4,
        dodge = 0
    },
    [5] = {
        movement_cost = 3,
        dodge = 0
    },
    [6] = {
        movement_cost = 5,
        dodge = 0
    },
    [7] = {
        movement_cost = 2,
        dodge = 0
    }
}

local record MapLayers
    metatiles: Userdata
    front_wall: Userdata
    mid_wall: Userdata
    back_wall: Userdata
    ground: Userdata
end

local record MapMetadata
    player_spawners: { integer: TilePoint }
    enemy_spawners: { integer: { TilePoint } }
end

local record BattleMap    
    width: integer
    height: integer
    layers: MapLayers 
    metadata: MapMetadata
end

function BattleMap:get_terrain(tile: TilePoint): TerrainData
    local tile_sprite = self.battle_map.layers.ground:get(tile.x,tile.y)
    local flags = fget(tile_sprite)
    local terrain = (flags & 0xD) >> 1
    return TERRAIN_DATA[terrain]
end


return {
    MapLayers = MapLayers,
    MapMetadata = MapMetadata,
    BattleMap = BattleMap,
    TerrainData = TerrainData,
}
