return {
    map_id = "village_overrun",
    variant_sets = {
        {
            deployment = "deployment_w",
            spawn_groups = {
                { zone = "pod_w",         role = "patrol", facing = "east"  },
                { zone = "house_w_guard", role = "guard",  facing = "east"  },
                { zone = "house_n_guard", role = "guard",  facing = "south" },
                { zone = "house_e_guard", role = "guard",  facing = "west"  },
                { zone = "boss_ne",       role = "boss",   facing = "north" },
            },
        },
        {
            deployment = "deployment_e",
            spawn_groups = {
                { zone = "pod_e",         role = "patrol", facing = "west"  },
                { zone = "pod_s",         role = "patrol", facing = "north" },
                { zone = "house_w_guard", role = "guard",  facing = "east"  },
                { zone = "house_n_guard", role = "guard",  facing = "south" },
                { zone = "house_e_guard", role = "guard",  facing = "west"  },
                { zone = "boss_ne",       role = "boss",   facing = "north" },
            },
        },
        {
            deployment = "deployment_n",
            spawn_groups = {
                { zone = "pod_s",         role = "patrol", facing = "north" },
                { zone = "pod_sw",        role = "patrol", facing = "east"  },
                { zone = "house_w_guard", role = "guard",  facing = "east"  },
                { zone = "house_n_guard", role = "guard",  facing = "south" },
                { zone = "house_e_guard", role = "guard",  facing = "west"  },
                { zone = "boss_sw",       role = "boss",   facing = "north" },
            },
        },
    }
}
