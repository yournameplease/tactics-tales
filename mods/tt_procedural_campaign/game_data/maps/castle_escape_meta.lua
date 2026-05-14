return {
    map_id = "castle_escape",
    variant_sets = {
        {
            deployment   = "deployment",
            spawn_groups = {
                { zone = "escape",  role = "patrol", facing = "east" },
                { zone = "pod_1",   role = "patrol", facing = "east" },
                { zone = "pod_2",   role = "patrol", facing = "east" },
                { zone = "ambush_n_1", role = "ambush", facing = "west" },
                { zone = "ambush_n_2", role = "ambush", facing = "west" },
                { zone = "wall_1",  role = "patrol", facing = "west" },
            },
        }
    }
}
