-- This file shims the Picotron API for testing in a standard Lua environment.

local lfs = require("lfs")

-- various global configs
---@type DynamicConfig
_G.DYNAMIC_CONFIG = {
    log_level = "NONE",
    draw_flexbox_debug = false,
    draw_target_debug = false,
    head_scale = 1,
    dialogue_speed = "normal",
    input_group = "mouse_and_keyboard",
}

_G.DATP = ""

-- logger
require("src.tactics.debug")
require("src.tactics.config")

-- Mock Userdata implementation
---@class MockUserdataState
---@field width integer
---@field height integer
---@field data number[][]

local MockUserdata_mt
local internal_data = setmetatable({}, { __mode = "k" })

---@param width integer
---@param height integer
---@return userdata
local function create_mock_userdata(width, height)
    local data = {}
    for y = 0, height - 1 do
        data[y] = {}
        for x = 0, width - 1 do
            data[y][x] = 0
        end
    end
    local ud = setmetatable({ x = 0, y = 0, z = 0 }, MockUserdata_mt)
    internal_data[ud] = { width = width, height = height, data = data }
    return ud
end

---@param a userdata
---@param b userdata|number
---@param op fun(x: number, y: number): number
---@return userdata
local function elementwise_op(a, b, op)
    local state_a = internal_data[a]
    local w = state_a.width
    local h = state_a.height
    local result_ud = create_mock_userdata(w, h)
    local state_res = internal_data[result_ud]

    if type(b) == "table" then
        local state_b = internal_data[b]
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                state_res.data[y][x] = op(state_a.data[y][x], state_b.data[y][x])
            end
        end
    else
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                state_res.data[y][x] = op(state_a.data[y][x], b)
            end
        end
    end
    return result_ud
end

MockUserdata_mt = {
    __add  = function(a, b) return elementwise_op(a, b, function(x, y) return x + y end) end,
    __sub  = function(a, b) return elementwise_op(a, b, function(x, y) return x - y end) end,
    __band = function(a, b) return elementwise_op(a, b, function(x, y) return x & y end) end,
    __bor  = function(a, b) return elementwise_op(a, b, function(x, y) return x | y end) end,
    __bxor = function(a, b) return elementwise_op(a, b, function(x, y) return x ~ y end) end,
    __bnot = function(a)
        local state = internal_data[a]
        local w = state.width
        local h = state.height
        local result_ud = create_mock_userdata(w, h)
        local state_res = internal_data[result_ud]
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                state_res.data[y][x] = ~state.data[y][x]
            end
        end
        return result_ud
    end,
    __shl = function(a, b) return elementwise_op(a, b, function(x, y) return x << y end) end,
    __shr = function(a, b) return elementwise_op(a, b, function(x, y) return x >> y end) end,
    __index = {
        width = function(self)
            return internal_data[self].width
        end,
        height = function(self)
            return internal_data[self].height
        end,
        get = function(self, x, y)
            return math.floor(internal_data[self].data[y][x])
        end,
        set = function(self, x, ...)
            local state = internal_data[self]
            local args = { ... }
            for y = 0, math.min(state.height - 1, #args - 1) do
                state.data[y][x] = args[y + 1]
            end
        end,
        sort = function(self)
            local state = internal_data[self]
            for x = 0, state.width - 1 do
                local column = {}
                for y = 0, state.height - 1 do
                    table.insert(column, state.data[y][x])
                end
                table.sort(column)
                for y = 0, state.height - 1 do
                    state.data[y][x] = column[y + 1]
                end
            end
        end,
    },
}

local _sprite_flags = {}

local pt_shim = {
    menuitem       = function(_id_or_item, _label, _action) end,
    sfx            = function(_n, _channel, _offset, _length, _pan, _mix_volume) end,
    music          = function(_n, _fade_len, _channel_mask, _base_addr, _tick_offset) end,
    note           = function(_pitch, _inst, _vol, _effect, _effect_p, _channel, _retrig, _panning) end,
    cocreate       = coroutine.create,
    coresume       = coroutine.resume,
    costatus       = coroutine.status,
    yield          = coroutine.yield,
    cd             = function(_path) end,
    fstat          = function(_path) return nil, nil, nil end,
    fullpath       = function(filename) return "/mock/" .. tostring(filename) end,
    ls             = function(path)
        local files = {}
        if not pcall(lfs.dir, path) then
            return nil
        end
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                table.insert(files, file)
            end
        end
        return files
    end,
    cp             = function(_src, _dest) end,
    mv             = function(_src, _dest) end,
    rm             = function(_filename) end,
    pwd            = function() return "/mock/" end,
    fetch          = function(_filename) return nil, nil end,
    store          = function(_filename, _object, _metadata) end,
    fetch_metadata = function(_filename) return nil end,
    store_metadata = function(_filename, _metadata) end,
    mkdir          = function(_name) end,
    mount          = function(_target, _origin) end,
    include        = function(path)
        local trimmed_path = string.gsub(path, "%.lua", "")
        return require(trimmed_path)
    end,
    vid            = function(_mode) end,
    cls            = function(_col) end,
    print          = function(value, x, y, _col)
        return x + #tostring(value) * 4, y
    end,
    clip           = function(_x, _y, _w, _h, _clip_previous) end,
    pset           = function(_x, _y, _col) end,
    pget           = function(_x, _y) return 0 end,
    fget           = function(n, f)
        local flags = _sprite_flags[n] or 0
        if f ~= nil then
            return (flags >> f) & 1 == 1
        end
        return flags
    end,
    fset           = function(n, f, val)
        local flags = _sprite_flags[n] or 0
        if val then
            _sprite_flags[n] = flags | (1 << f)
        else
            _sprite_flags[n] = flags & ~(1 << f)
        end
    end,
    cursor         = function(_x, _y, _col) end,
    color      = function(_col) end,
    camera     = function(_x, _y) return 0, 0 end,
    circ           = function(_x, _y, _r, _col) end,
    circfill       = function(_x, _y, _r, _col) end,
    oval           = function(_x0, _y0, _x1, _y1, _col) end,
    ovalfill       = function(_x0, _y0, _x1, _y1, _col) end,
    line           = function(_x0, _y0, _x1, _y1, _col) end,
    rect           = function(_x0, _y0, _x1, _y1, _col) end,
    rrect          = function(_x, _y, _w, _h, _radius, _col) end,
    rectfill       = function(_x0, _y0, _x1, _y1, _col) end,
    rrectfill      = function(_x, _y, _w, _h, _radius, _col) end,
    pal        = function(_c0, _c1, _p) end,
    palt       = function(_c, _is_transparent) end,
    spr            = function(_s, _x, _y, _flip_x, _flip_y) end,
    sspr           = function(_s, _sx, _sy, _sw, _sh, _dx, _dy, _dw, _dh, _flip_x, _flip_y) end,
    fillp          = function(...) local _ = { ... } end,
    get_spr        = function(_index) return create_mock_userdata(8, 8) end,
    set_spr        = function(_index, _ud) end,
    flip           = function(_flags) end,
    btn            = function(_button, _player) return false end,
    btnp           = function(_button, _player) return false end,
    key            = function(_k, _raw) return false end,
    keyp           = function(_k, _raw) return false end,
    clear_key      = function(_k) end,
    peektext       = function() return false end,
    readtext       = function(_clear) return "" end,
    mouse      = function(_new_mx, _new_my) return 0, 0, 0, 0, 0 end,
    mouselock      = function(_lock, _event_sensitivity, _move_sensitivity) return 0, 0 end,
    map            = function(_src, _tile_x, _tile_y, _sx, _sy, _tiles_x, _tiles_y, _p8layers, _tile_w, _tile_h) end,
    mget           = function(_x, _y) return 0 end,
    mset           = function(_x, _y, _val) end,
    tline3d        = function(_src_ud, _x0, _y0, _x1, _y1, _u0, _v0, _u1, _v1, _w0, _w1, _flags) end,
    min            = math.min,
    max            = math.max,
    mid            = function(x, y, z)
        if x > y then x, y = y, x end
        if y > z then y, z = z, y end
        if x > y then x, y = y, x end
        return y
    end,
    flr            = math.floor,
    ceil           = math.ceil,
    rnd            = function(limit)
        if type(limit) == "table" then
            return limit[math.random(#limit)]
        else
            return math.random() * limit
        end
    end,
    srand          = math.randomseed,
    tonum          = tonumber,
    abs            = math.abs,
    absf           = math.abs,
    sgn            = function(n)
        if n > 0 then return 1
        elseif n < 0 then return -1
        else return 0
        end
    end,
    atan2          = function(dx, dy) return math.atan(dy, dx) end,
    sin            = math.sin,
    cos            = math.cos,
    sqrt           = math.sqrt,
    peek           = function(_addr, _n) return 0 end,
    peek2          = function(_addr, _n) return 0 end,
    peek4          = function(_addr, _n) return 0 end,
    peek8          = function(_addr, _n) return 0 end,
    poke           = function(_addr, ...) local _ = { ... } end,
    poke2          = function(_addr, ...) local _ = { ... } end,
    poke4          = function(_addr, ...) local _ = { ... } end,
    poke8          = function(_addr, ...) local _ = { ... } end,
    memcpy         = function(_dest_addr, _source_addr, _len) end,
    memset         = function(_dest_addr, _val, _len) end,
    pod            = function(val, _flags, _metadata) return tostring(val) end,
    unpod          = function(val) return val, nil end,
    chr            = string.char,
    sub            = function(s, start, pos)
        local one_char = pos ~= nil and type(pos) ~= "number"
        if one_char then
            return string.sub(s, start, start)
        else
            return string.sub(s, start, pos)
        end
    end,
    split          = function(str, separator)
        local result = {}
        if #separator == 0 then
            for i = 1, #str do table.insert(result, str:sub(i, i)) end
            return result
        end
        local start = 1
        while true do
            local find_start, find_end = str:find(separator, start, true)
            if not find_start then
                table.insert(result, str:sub(start))
                break
            end
            table.insert(result, str:sub(start, find_start - 1))
            start = find_end + 1
        end
        return result
    end,
    type           = type,
    env            = function() return {} end,
    exit           = function(_exit_code) end,
    printh         = print,
    create_process = function(_filename, _env) end,
    stop           = function(message) error(message or "stopped") end,
    time           = function() return os.time() end,
    t              = function() return os.time() end,
    date           = function(format, t, _delta) return os.date(format, t) end,
    set_clipboard  = function(_text) end,
    get_clipboard  = function() return "" end,
    on_event       = function(_event, _callback) end,
    send_message   = function(_pid, _event) end,
    pid            = function() return 1 end,
    notify         = function(message) print("NOTIFY:", message) end,
    stat           = function(_id, _addr) end,
    theme          = function(_which) end,
    open           = function(_file) end,
    add            = function(t, v, i)
        if i then
            table.insert(t, i, v)
        else
            table.insert(t, v)
        end
    end,
    del            = function(t, v)
        for i = #t, 1, -1 do
            if t[i] == v then
                return table.remove(t, i)
            end
        end
        return nil
    end,
    deli           = table.remove,
    count          = function(t, v)
        if v == nil then return #t end
        local c = 0
        for _, val in ipairs(t) do
            if val == v then c = c + 1 end
        end
        return c
    end,
    all            = function(t)
        local i = 0
        return function()
            i = i + 1
            return t[i]
        end
    end,
    foreach        = function(t, f)
        for _, v in ipairs(t) do f(v) end
    end,
    pack           = function(...) return table.pack(...) end,
    unpack         = table.unpack,
    userdata       = function(_data_type, width, height, _data) return create_mock_userdata(width, height) end,
    vec            = function(...)
        local args = { ... }
        local ud = create_mock_userdata(1, #args)
        local state = internal_data[ud]
        for i, v in ipairs(args) do
            state.data[i - 1][0] = v
        end
        return ud
    end,
    get_display        = function() return create_mock_userdata(240, 136) end,
    set_draw_target    = function(_ud) end,
    get_draw_target    = function() return create_mock_userdata(240, 136) end,
    window = function(_attribs) end,
    wrangle_working_file = function(_save_state, _load_state, _untitled_filename, _get_hlocation, _set_hlocation) end,
    pwf                = function() return nil end,
}

-- copy shim keys onto _G for bare global access (used by mods and legacy call sites)
for k, v in pairs(pt_shim) do
    if _G[k] == nil then
        _G[k] = v
    end
end
