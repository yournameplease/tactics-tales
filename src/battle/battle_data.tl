require("src/battle/victory_conditions")

--[[ Data contains:
- map_file or generator
- victory condition
- config
  - specify input for utility map tiles
]]

local BATTLE_DATA = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        victory_conditions = { {
            type = "ROUT"
        } },
        failure_conditions = { {
            type = "TURN_LIMIT"
        } },
        enemies = {
            { template = "bandit_goon" },
            { template = "bandit_boss" }
        }
    }
}

return BATTLE_DATA
