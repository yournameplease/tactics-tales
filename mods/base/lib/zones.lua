local zones = {}

---@param budget integer
---@param slot_cost integer
---@return integer
function zones.unit_count(budget, slot_cost)
    return math.floor(budget / slot_cost)
end

---@param rect RectZone
---@param pattern "grid"|"checkerboard"|"random"
---@param count integer
---@param rng? RngInstance
---@return Point[]
function zones.expand(rect, pattern, count, rng)
    if pattern == "grid" then
        local result = {}
        for row = 0, rect.h - 1 do
            for col = 0, rect.w - 1 do
                if #result >= count then break end
                result[#result + 1] = { x = rect.x + col, y = rect.y + row }
            end
            if #result >= count then break end
        end
        return result
    elseif pattern == "checkerboard" then
        local result = {}
        for row = 0, rect.h - 1 do
            for col = 0, rect.w - 1 do
                if #result >= count then break end
                local tx = rect.x + col
                local ty = rect.y + row
                if (tx + ty) % 2 == 0 then
                    result[#result + 1] = { x = tx, y = ty }
                end
            end
            if #result >= count then break end
        end
        return result
    elseif pattern == "random" then
        local all = {}
        for row = 0, rect.h - 1 do
            for col = 0, rect.w - 1 do
                all[#all + 1] = { x = rect.x + col, y = rect.y + row }
            end
        end
        if rng then
            -- Fisher-Yates shuffle
            for i = #all, 2, -1 do
                local j = rng:rndi(i) + 1
                all[i], all[j] = all[j], all[i]
            end
        end
        local result = {}
        for i = 1, math.min(count, #all) do
            result[i] = all[i]
        end
        return result
    end
    return {}
end

return zones
