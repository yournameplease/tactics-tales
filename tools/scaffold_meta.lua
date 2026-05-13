#!/usr/bin/env lua
-- Scaffold a `_meta.lua` sidecar for a Tiled-exported pod-mission map.
-- Usage: lua tools/scaffold_meta.lua <path-to-map.lua> [--force]
-- Standalone host-Lua tool; not loaded by the Picotron runtime.
---@diagnostic disable: undefined-global

local function die(msg)
    io.stderr:write("scaffold_meta: " .. msg .. "\n")
    os.exit(1)
end

local input_path, force
for i = 1, #arg do
    local a = arg[i]
    if a == "--force" then
        force = true
    elseif a:sub(1, 2) == "--" then
        die("unknown flag: " .. a)
    else
        if input_path then die("multiple input paths given") end
        input_path = a
    end
end

if not input_path then
    die("usage: lua tools/scaffold_meta.lua <path-to-map.lua> [--force]")
end

local dir, file = input_path:match("^(.*/)([^/]+)$")
if not file then dir, file = "", input_path end
local stem = file:match("^(.-)%.lua$") or file
local output_path = dir .. stem .. "_meta.lua"

local f = io.open(output_path, "r")
if f then
    f:close()
    if not force then
        die(output_path .. " already exists (pass --force to overwrite)")
    end
end

local ok, map = pcall(dofile, input_path)
if not ok then die("failed to load " .. input_path .. ": " .. tostring(map)) end
if type(map) ~= "table" or type(map.layers) ~= "table" then
    die(input_path .. " does not look like a Tiled Lua map")
end

local mid_x = (map.width or 0) * (map.tilewidth or 0) / 2

local function has_segment(name, target)
    for seg in name:gmatch("[^_]+") do
        if seg == target then return true end
    end
    return false
end

local function classify_role(name)
    if has_segment(name, "boss")  then return "boss"  end
    if has_segment(name, "guard") then return "guard" end
    return "patrol"
end

local deployments = {}
local candidates  = {}

for _, layer in ipairs(map.layers) do
    if layer.type == "objectgroup" and type(layer.name) == "string" then
        local name = layer.name
        if name == "deployment" or name:match("^deployment_") then
            deployments[#deployments + 1] = name
        elseif name:match("^reinforce_") then
            -- ignore; resolver picks these up as zones automatically
        else
            local first = layer.objects and layer.objects[1]
            local x = first and first.x or 0
            local facing = (x < mid_x) and "east" or "west"
            candidates[#candidates + 1] = {
                zone   = name,
                role   = classify_role(name),
                facing = facing,
            }
        end
    end
end

table.sort(deployments)
table.sort(candidates, function(a, b) return a.zone < b.zone end)

-- Column-align zone/role/facing for readable output.
local function quoted(s) return string.format("%q", s) end

local max_zone, max_role = 0, 0
for _, c in ipairs(candidates) do
    if #quoted(c.zone) > max_zone then max_zone = #quoted(c.zone) end
    if #quoted(c.role) > max_role then max_role = #quoted(c.role) end
end

local out = {}
local function emit(s) out[#out + 1] = s end

emit("return {\n")
emit(string.format("    map_id = %q,\n", stem))

if #deployments == 0 then
    io.stderr:write("scaffold_meta: warning: no deployment_* layers found; emitting empty variant_sets\n")
    emit("    variant_sets = {}\n")
else
    emit("    variant_sets = {\n")
    for di, dep in ipairs(deployments) do
        emit("        {\n")
        emit(string.format("            deployment   = %q,\n", dep))
        if #candidates == 0 then
            emit("            spawn_groups = {},\n")
        else
            emit("            spawn_groups = {\n")
            for _, c in ipairs(candidates) do
                local zq = quoted(c.zone) .. ","
                local rq = quoted(c.role) .. ","
                emit(string.format(
                    "                { zone = %-" .. (max_zone + 1) .. "s role = %-" .. (max_role + 1) .. "s facing = %q },\n",
                    zq, rq, c.facing
                ))
            end
            emit("            },\n")
        end
        emit("        }" .. (di < #deployments and "," or "") .. "\n")
    end
    emit("    }\n")
end
emit("}\n")

local handle, err = io.open(output_path, "w")
if not handle then die("cannot write " .. output_path .. ": " .. tostring(err)) end
handle:write(table.concat(out))
handle:close()

io.write("wrote " .. output_path .. "\n")
io.write(string.format("  %d deployment(s), %d spawn group(s)\n", #deployments, #candidates))
