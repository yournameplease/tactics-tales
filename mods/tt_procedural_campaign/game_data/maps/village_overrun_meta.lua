local ALL_SPAWN_GROUPS = {
    { zone = "pod_w",         role = "patrol", facing = "east"  },
    { zone = "pod_e",         role = "patrol", facing = "west"  },
    { zone = "pod_nw",        role = "patrol", facing = "south" },
    { zone = "pod_sw",        role = "patrol", facing = "east"  },
    { zone = "pod_se",        role = "patrol", facing = "west"  },
    { zone = "pod_s",         role = "patrol", facing = "north" },
    { zone = "pod_n_wall",    role = "patrol", facing = "south" },
    { zone = "pod_s_wall",    role = "patrol", facing = "north" },
    { zone = "house_w_guard", role = "guard",  facing = "east"  },
    { zone = "house_n_guard", role = "guard",  facing = "south" },
    { zone = "house_e_guard", role = "guard",  facing = "west"  },
    { zone = "boss_sw",       role = "boss",   facing = "north" },
    { zone = "boss_se",       role = "boss",   facing = "north" },
    { zone = "boss_ne",       role = "boss",   facing = "north" },
}

return {
    map_id = "village_overrun",
    variant_sets = {
        {
            deployment   = "deployment_w",
            spawn_groups = ALL_SPAWN_GROUPS,
        },
        {
            deployment   = "deployment_e",
            spawn_groups = ALL_SPAWN_GROUPS,
        },
        {
            deployment   = "deployment_n",
            spawn_groups = ALL_SPAWN_GROUPS,
        },
    }
}
