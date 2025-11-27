require("src/util/data_utils")

VICTORY_CONDITIONS = enum{
        "ROUT",
        "DEFEAT_BOSS",
        "SURVIVE",
        "ESCAPE"
}

FAILURE_CONDITIONS = enum{
    "LEADER_DIES",
    "TURN_LIMIT"
}
