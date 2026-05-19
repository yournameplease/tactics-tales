---@brief
--- Objective-aware cell placement for procgen maps.
--- See docs/superpowers/specs/2026-05-18-procgen-objective-placement-design.md

local graph_mod = require("src.tactics.battle.map.procgen.graph")

---@class ProcgenPlacement
---@field deployment_cell integer  1-based macro-grid cell index
---@field boss_cell integer?       present for kill_boss only
---@field escape_cell integer?     present for escape only

local placement = {}

--- Select deployment and objective cells based on the given objective.
---@param g ConnectionGraph
---@param objective string  One of "kill_boss", "escape", "rout", "defend"
---@param rng RngInstance
---@return ProcgenPlacement
function placement.select(g, objective, rng)
    if objective == "kill_boss" or objective == "escape" then
        local depths = graph_mod.node_depths(g, 1)
        local far_cell = nil
        local max_d = -1
        for node, d in pairs(depths) do
            if d == 0 then far_cell = node end
            if d > max_d then max_d = d end
        end
        local candidates = {}
        for node, d in pairs(depths) do
            if d == max_d then table.insert(candidates, node) end
        end
        for i = 1, #candidates - 1 do
            for j = i + 1, #candidates do
                if candidates[j] < candidates[i] then
                    candidates[i], candidates[j] = candidates[j], candidates[i]
                end
            end
        end
        local deployment_cell = candidates[rng:rndi(#candidates) + 1]
        if objective == "kill_boss" then
            return { deployment_cell = deployment_cell, boss_cell = far_cell }
        else
            return { deployment_cell = deployment_cell, escape_cell = far_cell }
        end

    elseif objective == "rout" or objective == "defend" then
        local ecc = graph_mod.node_eccentricities(g)
        local candidates = {}
        for node, e in pairs(ecc) do
            if #(g.adjacency[node] or {}) >= 2 then
                table.insert(candidates, { node = node, ecc = e, degree = #g.adjacency[node] })
            end
        end
        if #candidates == 0 then
            for node, e in pairs(ecc) do
                table.insert(candidates, { node = node, ecc = e, degree = #(g.adjacency[node] or {}) })
            end
        end
        local min_ecc = math.huge
        for _, c in ipairs(candidates) do
            if c.ecc < min_ecc then min_ecc = c.ecc end
        end
        local max_deg = -1
        for _, c in ipairs(candidates) do
            if c.ecc == min_ecc and c.degree > max_deg then max_deg = c.degree end
        end
        local top = {}
        for _, c in ipairs(candidates) do
            if c.ecc == min_ecc and c.degree == max_deg then
                table.insert(top, c.node)
            end
        end
        for i = 1, #top - 1 do
            for j = i + 1, #top do
                if top[j] < top[i] then top[i], top[j] = top[j], top[i] end
            end
        end
        local deployment_cell = top[rng:rndi(#top) + 1]
        return { deployment_cell = deployment_cell }

    else
        error("placement.select: unknown objective '" .. tostring(objective) .. "'")
    end
end

return placement
