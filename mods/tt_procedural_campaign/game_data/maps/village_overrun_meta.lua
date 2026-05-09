return {
    -- Each entry describes one playable variant of this map.
    -- `deployment` is the player spawn zone for that variant.
    -- `excludes` lists enemy zones that overlap the deployment area and must
    -- be omitted when this variant is active.
    variant_sets = {
        {
            deployment = "deployment_w",
            excludes   = { "pod_sw", "boss_sw" },
        },
        {
            deployment = "deployment_e",
            excludes   = { "pod_se", "boss_se" },
        },
        {
            deployment = "deployment_n",
            excludes   = { "pod_nw", "boss_ne" },
        },
    }
}
