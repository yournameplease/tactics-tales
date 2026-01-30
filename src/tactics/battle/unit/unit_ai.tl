local Side = require("src/tactics/character/object/character").Side

local enum MoveAI
    "infinity"
    "one"
    "two"
    "zero"
end

local record UnitAI
    move: MoveAI
    target_side: Side
end

local unit_ai = {
    MoveAI = MoveAI,
    UnitAI = UnitAI,
}

return unit_ai
