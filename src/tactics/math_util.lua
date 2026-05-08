---@class MathUtil
local math_util = {}

--- Smooth cubic easing: 3t²−2t³, clamped to [0,1].
---@param t number
---@return number
function math_util.smoothstep(t)
    t = math.max(0, math.min(1, t))
    return t * t * (3 - 2 * t)
end

return math_util
