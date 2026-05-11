return {
    map_id = "village_overrun",
    variant_sets = {
        {
            deployment   = "deployment_w",
            excludes     = { "pod_sw" },
            spawn_groups = {
                { zone = "pod_w",   role = "patrol", facing = "east"  },
                { zone = "boss_ne", role = "boss",   facing = "north" },
            },
        },
        {
            deployment   = "deployment_e",
            spawn_groups = {
                { zone = "pod_e",      role = "patrol", facing = "west"  },
                { zone = "pod_s",      role = "patrol", facing = "north" },
                { zone = "boss_ne",    role = "boss",   facing = "north" },
            },
        },
        {
            deployment   = "deployment_n",
            spawn_groups = {
                { zone = "pod_s",   role = "patrol", facing = "north" },
                { zone = "pod_sw",  role = "patrol", facing = "east"  },
                { zone = "boss_sw", role = "boss",   facing = "north" },
            },
        },
    }
}
