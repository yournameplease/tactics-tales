require("src/battle/victory_conditions.lua")

--[[ Data contains:
- map_file or generator
- victory condition
- config
  - specify input for utility map tiles
]]

BATTLE_DATA = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        victory_conditions = { {
            type = VICTORY_CONDITIONS.ROUT
        } },
        failure_conditions = { {
            type = FAILURE_CONDITIONS.TURN_LIMIT
        } },
        enemies = {
            { template = "bandit_goon" },
            { template = "bandit_boss" }
        }
    }
}
