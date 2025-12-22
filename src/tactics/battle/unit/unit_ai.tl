
local enum MoveAI
    "infinity"
    "one"
    "two"
    "zero"
end

local enum TargetAI
    "player"
end

local record UnitAI
    move: MoveAI
    target: TargetAI
end

local unit_ai = {
    MoveAI = MoveAI,
    TargetAI = TargetAI,
    UnitAI = UnitAI,
}

return unit_ai
