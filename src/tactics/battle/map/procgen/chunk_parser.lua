---@brief
--- Parses `.chunks` text files into structured chunk records.
--- See docs/specs/procgen-map-spec.md §7 for the file format.

---@class ChunkRecord
---@field name string
---@field width integer Interior width (excludes the 1-tile border ring).
---@field height integer Interior height (excludes the 1-tile border ring).
---@field rows string[] Full glyph rows including the border ring.
---@field tags string[]
---@field exits ChunkExits

---@class ChunkExits
---@field north ExitZone?
---@field south ExitZone?
---@field east ExitZone?
---@field west ExitZone?

---@class ExitZone
---@field min integer 1-indexed inclusive start of the run on its face
---@field max integer 1-indexed inclusive end of the run on its face

local chunk_parser = {}

--- Find the single contiguous run of `marker` in `s`.
--- Returns nil if no marker found. Returns {min, max} 1-indexed inclusive.
---@param s string
---@param marker string Single char to find a run of.
---@return ExitZone?
local function find_run(s, marker)
    local first, last
    for i = 1, #s do
        local c = s:sub(i, i)
        if c == marker then
            if not first then first = i end
            last = i
        end
    end
    if not first then return nil end
    return { min = first, max = last }
end

--- Validate a parsed chunk's glyph grid. Raises on any structural violation.
---@param name string
---@param rows string[]
---@param w integer
---@param h integer
local function validate(name, rows, w, h)
    local function fail(msg)
        error("chunk '" .. name .. "': " .. msg)
    end

    if w - 2 < 3 or h - 2 < 3 then
        fail("interior must be at least 3x3 (got " .. (w - 2) .. "x" .. (h - 2) .. ")")
    end

    for r = 1, h do
        if #rows[r] ~= w then
            fail("row " .. r .. " width " .. #rows[r] .. " does not match declared width " .. w)
        end
    end

    -- Corners must be `#`.
    if rows[1]:sub(1, 1) ~= "#" or rows[1]:sub(w, w) ~= "#"
        or rows[h]:sub(1, 1) ~= "#" or rows[h]:sub(w, w) ~= "#" then
        fail("corner tiles must be '#'")
    end

    local VALID_NORTH = { ["#"] = true, ["^"] = true }
    local VALID_SOUTH = { ["#"] = true, ["v"] = true }
    local VALID_WEST  = { ["#"] = true, ["<"] = true }
    local VALID_EAST  = { ["#"] = true, [">"] = true }
    local VALID_INTERIOR = {
        ["#"] = true, ["."] = true,
        ["i"] = true, ["r"] = true, ["t"] = true, ["c"] = true,
        ["d"] = true, ["p"] = true, ["a"] = true, ["g"] = true,
    }

    for y = 1, h do
        local row = rows[y]
        for x = 1, w do
            local c = row:sub(x, x)
            local is_corner = (y == 1 or y == h) and (x == 1 or x == w)
            local is_border = y == 1 or y == h or x == 1 or x == w
            if is_corner then
                -- already validated above
            elseif is_border then
                local valid
                if y == 1 then valid = VALID_NORTH
                elseif y == h then valid = VALID_SOUTH
                elseif x == 1 then valid = VALID_WEST
                else valid = VALID_EAST end
                if not valid[c] then
                    fail("invalid border character '" .. c .. "' at (" .. x .. "," .. y .. ")")
                end
            else
                if not VALID_INTERIOR[c] then
                    fail("invalid interior character '" .. c .. "' at (" .. x .. "," .. y .. ")")
                end
            end
        end
    end

    -- A face may have at most one contiguous run of directional markers.
    local function count_runs(s, marker)
        local runs, in_run = 0, false
        for i = 1, #s do
            local c = s:sub(i, i)
            if c == marker then
                if not in_run then runs = runs + 1 end
                in_run = true
            else
                in_run = false
            end
        end
        return runs
    end

    local west_col, east_col = "", ""
    for r = 1, h do
        west_col = west_col .. rows[r]:sub(1, 1)
        east_col = east_col .. rows[r]:sub(w, w)
    end

    if count_runs(rows[1], "^") > 1 then fail("north face has more than one exit run") end
    if count_runs(rows[h], "v") > 1 then fail("south face has more than one exit run") end
    if count_runs(west_col, "<") > 1 then fail("west face has more than one exit run") end
    if count_runs(east_col, ">") > 1 then fail("east face has more than one exit run") end
end

--- Check that `d` glyph presence matches the `deployment` tag.
---@param name string
---@param rows string[]
---@param w integer
---@param h integer
---@param tags string[]
local function validate_deployment_tag(name, rows, w, h, tags)
    local has_tag = false
    for _, t in ipairs(tags) do
        if t == "deployment" then has_tag = true end
    end

    local has_d = false
    for y = 2, h - 1 do
        for x = 2, w - 1 do
            if rows[y]:sub(x, x) == "d" then has_d = true end
        end
    end

    if has_tag and not has_d then
        error("chunk '" .. name .. "': deployment tag requires at least one 'd' glyph")
    end
    if has_d and not has_tag then
        error("chunk '" .. name .. "': 'd' glyph requires the deployment tag")
    end
end

local KNOWN_TAGS = {
    deployment  = true,
    boss_room   = true,
    escape_zone = true,
    rotate_90   = true,
    rotate_180  = true,
    flip_v      = true,
    flip_h      = true,
}

--- Emit warnings for unknown tags.
---@param name string
---@param tags string[]
local function warn_unknown_tags(name, tags)
    for _, t in ipairs(tags) do
        if not KNOWN_TAGS[t] then
            log.warn("chunk '" .. name .. "': unknown tag '" .. t .. "'")
        end
    end
end

--- Build the exit-zone table for a chunk from its glyph rows.
---@param rows string[]
---@param w integer
---@param h integer
---@return ChunkExits
local function derive_exits(rows, w, h)
    local west_col, east_col = "", ""
    for r = 1, h do
        west_col = west_col .. rows[r]:sub(1, 1)
        east_col = east_col .. rows[r]:sub(w, w)
    end
    return {
        north = find_run(rows[1], "^"),
        south = find_run(rows[h], "v"),
        west = find_run(west_col, "<"),
        east = find_run(east_col, ">"),
    }
end

--- Parse the contents of a `.chunks` file.
---@param text string
---@return ChunkRecord[]
function chunk_parser.parse(text)
    local lines = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line:sub(1, 2) ~= "--" then
            table.insert(lines, line)
        end
    end

    local chunks = {}
    local seen_names = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        if line == "" then
            i = i + 1
        else
            local name = line:match("^%[([^%]]+)%]$")
            assert(name, "expected label line, got: " .. line)
            i = i + 1

            local tags = {}
            local dim_line = lines[i]
            if not dim_line:match("^%d+ %d+$") then
                for tag in dim_line:gmatch("%S+") do
                    table.insert(tags, tag)
                end
                i = i + 1
                dim_line = lines[i]
            end
            local w, h = dim_line:match("^(%d+) (%d+)$")
            w, h = tonumber(w), tonumber(h)
            i = i + 1

            local rows = {}
            for _ = 1, h do
                table.insert(rows, lines[i])
                i = i + 1
            end

            assert(w and h, "expected dimension line for chunk '" .. name .. "'")
            assert(not seen_names[name], "duplicate chunk name '" .. name .. "'")
            seen_names[name] = true
            validate(name, rows, w, h)
            validate_deployment_tag(name, rows, w, h, tags)
            warn_unknown_tags(name, tags)
            table.insert(chunks, {
                name = name,
                width = w - 2,
                height = h - 2,
                rows = rows,
                tags = tags,
                exits = derive_exits(rows, w, h),
            })
        end
    end

    return chunks
end

--- Read a `.chunks` file via Picotron's `fetch()` and parse it.
---@param path string Absolute or DATP-relative path to the .chunks file.
---@return ChunkRecord[]
function chunk_parser.load_theme(path)
    local text = fetch(path)
    assert(text, "chunk_parser.load_theme: fetch returned nil for '" .. path .. "'")
    return chunk_parser.parse(text)
end

return chunk_parser
