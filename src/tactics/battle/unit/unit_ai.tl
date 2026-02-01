---@brief
--- Data structures for defining the behavior of an AI-controlled unit.
--- Includes movement style and targeting preferences.

local Side = require("src.tactics.character.object.character").Side

local enum MoveAI
    "infinity"
    "one"
    "two"
    "zero"
end

local record UnitAI
    move: MoveAI
    target_sides: {Side}
    exclude_tags: {string}
end

local unit_ai = {
    MoveAI = MoveAI,
    UnitAI = UnitAI,
}

return unit_ai
