---@brief
--- Objective-aware cell placement for procgen maps.
--- See docs/superpowers/specs/2026-05-18-procgen-objective-placement-design.md

local graph_mod = require("src.tactics.battle.map.procgen.graph")
local sort      = require("src.tactics.util.sort")

---@class ProcgenPlacement
---@field deployment_cell integer  1-based macro-grid cell index
---@field boss_cell integer?       present for kill_boss only
---@field escape_cell integer?     present for escape only
---@field enemy_cells table<integer, true>?  non-special cells designated as enemy rooms

local placement = {}

--- Roll enemy_cells for all nodes in g that are not in `specials`.
---@param g ConnectionGraph
---@param specials table<integer, true>
---@param prob number
---@param rng RngInstance
---@return table<integer, true>
local function roll_enemy_cells(g, specials, prob, rng)
    local enemy_cells = {}
    for node in pairs(g.adjacency) do
        if not specials[node] and rng:rndf() < prob then
            enemy_cells[node] = true
        end
    end
    return enemy_cells
end

--- Select deployment and objective cells based on the given objective.
---@param g ConnectionGraph
---@param objective string  One of "kill_boss", "escape", "rout", "defend"
---@param rng RngInstance
---@param theme ProcgenTheme?  Optional theme; provides target_deployment_distance when present.
---@return ProcgenPlacement
function placement.select(g, objective, rng, theme)
    local prob = theme and theme.enemy_room_probability or 0

    if objective == "kill_boss" or objective == "escape" then
        -- Step 1: pick end cell as the far pole.
        local d_from_start = graph_mod.bfs_distances(g, 1)
        local end_cell = 1
        for node, d in pairs(d_from_start) do
            if d > d_from_start[end_cell] then end_cell = node end
        end

        -- Step 2: pick deployment at target distance from end cell, or farthest if unreachable.
        local d_from_end = graph_mod.bfs_distances(g, end_cell)
        local max_d = -1
        for _, d in pairs(d_from_end) do
            if d > max_d then max_d = d end
        end
        local target_d = (theme and theme.target_deployment_distance) or max_d
        local pick_d = target_d <= max_d and target_d or max_d
        local candidates = {}
        for node, d in pairs(d_from_end) do
            if d == pick_d then table.insert(candidates, node) end
        end
        sort.by(candidates)
        local deployment_cell = candidates[rng:rndi(#candidates) + 1]

        if objective == "kill_boss" then
            local specials = { [deployment_cell] = true, [end_cell] = true }
            local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
            return { deployment_cell = deployment_cell, boss_cell = end_cell, enemy_cells = enemy_cells }
        else
            local specials = { [deployment_cell] = true, [end_cell] = true }
            local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
            return { deployment_cell = deployment_cell, escape_cell = end_cell, enemy_cells = enemy_cells }
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
        sort.by(top)
        local deployment_cell = top[rng:rndi(#top) + 1]
        local specials = { [deployment_cell] = true }
        local enemy_cells = roll_enemy_cells(g, specials, prob, rng)
        return { deployment_cell = deployment_cell, enemy_cells = enemy_cells }

    else
        error("placement.select: unknown objective '" .. tostring(objective) .. "'")
    end
end

return placement
