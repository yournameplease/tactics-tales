return {
    map_id = "castle_escape",
    variant_sets = {
        {
            deployment   = "deployment",
            spawn_groups = {
                { zone = "ally_1",  role = "patrol", facing = "west" },
                { zone = "ally_2",  role = "patrol", facing = "west" },
                { zone = "escape",  role = "patrol", facing = "east" },
                { zone = "pod_1",   role = "patrol", facing = "east" },
                { zone = "pod_2",   role = "patrol", facing = "east" },
                { zone = "pod_n_1", role = "patrol", facing = "west" },
                { zone = "pod_n_2", role = "patrol", facing = "west" },
                { zone = "wall_1",  role = "patrol", facing = "west" },
            },
        }
    }
}
