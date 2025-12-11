
global record MapLayers
    metatiles: Userdata
    front_wall: Userdata
    mid_wall: Userdata
    back_wall: Userdata
    ground: Userdata
end

global record MapMetadata
    player_spawners: { integer: TilePoint }
    enemy_spawners: { integer: { TilePoint } }
end

global record MapData
    width: integer
    height: integer
    layers: MapLayers 
    metadata: MapMetadata
end


return MapData
