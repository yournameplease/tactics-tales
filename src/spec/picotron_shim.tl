-- This file shims the Picotron API for testing in a standard Lua environment.
-- require("types.picotron") -- ensures the global types are loaded

local lfs = require("lfs")


-- utility error messages
-- _G.todo = function(message: string | nil): any
--     print("TODO: " .. (message or ""))
--     return nil
-- end
-- _G.unexpected = function(state: string)
--     error("UNEXPECTED: " .. state)
-- end

-- global context for mods
-- _G.lib = {}

-- various global configs
_G.DYNAMIC_CONFIG = {
    log_level = "INFO",
    draw_flexbox_debug = false,
    draw_target_debug = false,
    head_scale = 1,
    dialogue_speed = "normal",
}
-- _G.STATIC_CONFIG = {
--     SCREEN_WIDTH = 240,
--     SCREEN_HEIGHT = 136,
--     MAP_WIDTH = 128,
--     MAP_HEIGHT = 128,
--     TILE_WIDTH = 8,
--     TILE_HEIGHT = 8,
--     WALL_HEIGHT = 8,
-- }

-- logger
require("tactics/debug")
require("tactics/config")

-- _G.log = {
--     error = function(...) print("ERROR:", ...) end,
--     warn = function(...) print("WARN:", ...) end,
--     info = function(...) print("INFO:", ...) end,
--     debug = function(...) print("DEBUG:", ...) end,
--     trace = function(...) print("TRACE:", ...) end,
-- }

_G.DATP = ""

-- _G._init = function() end
-- _G._update = function() end
-- _G._draw = function() end


-- Mock Userdata implementation
local MockUserdata_mt: metatable<Userdata>
local internal_data = setmetatable({}, {__mode = "k"})

local function create_mock_userdata(width: integer, height: integer): Userdata
    local data: {{number}} = {}
    for y = 0, height - 1 do
        data[y] = {}
        for x = 0, width - 1 do
            data[y][x] = 0
        end
    end

    local ud: Userdata = setmetatable({x=0,y=0,z=0}, MockUserdata_mt)
    internal_data[ud] = {
        width = width,
        height = height,
        data = data,
    }
    
    return ud
end

local function elementwise_op(a: Userdata, b: Userdata | number, op: function(number, number):number): Userdata
    local state_a = internal_data[a]
    local w = state_a.width
    local h = state_a.height
    local result_ud = create_mock_userdata(w, h)
    local state_res = internal_data[result_ud]

    if type(b) == "table" then -- Userdata
        local state_b = internal_data[b as Userdata]
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                state_res.data[y][x] = op(state_a.data[y][x], state_b.data[y][x])
            end
        end
    else -- number
        local num = b as number
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                state_res.data[y][x] = op(state_a.data[y][x], num)
            end
        end
    end
    return result_ud
end

MockUserdata_mt = {
    __add = function(a: Userdata, b: Userdata | number): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return x + y end)
    end,
    __sub = function(a: Userdata, b: Userdata | number): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return x - y end)
    end,
    __band = function(a: Userdata, b: Userdata | integer): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return (x as integer) & (y as integer) end)
    end,
    __bor = function(a: Userdata, b: Userdata | integer): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return (x as integer) | (y as integer) end)
    end,
    __bxor = function(a: Userdata, b: Userdata | integer): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return (x as integer) ~ (y as integer) end)
    end,
    __bnot = function(a: Userdata): Userdata
        local state = internal_data[a]
        local w = state.width
        local h = state.height
        local result_ud = create_mock_userdata(w, h)
        local state_res = internal_data[result_ud]
        for y = 0, h - 1 do
            for x = 0, w - 1 do
                state_res.data[y][x] = ~(state.data[y][x])
            end
        end
        return result_ud
    end,
    __shl = function(a: Userdata, b: integer): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return (x as integer) << (y as integer) end)
    end,
    __shr = function(a: Userdata, b: integer): Userdata
        return elementwise_op(a, b, function(x: number, y: number): number return (x as integer) >> (y as integer) end)
    end,
    __index = {
        width = function(self: Userdata): integer
            return internal_data[self].width
        end,
        height = function(self: Userdata): integer
            return internal_data[self].height
        end,
        get = function(self: Userdata, x: integer, y: integer): integer
            return math.floor(internal_data[self].data[y][x])
        end,
        set = function(self: Userdata, x: integer, ...)
            local state = internal_data[self]
            local args = {...}
            for y = 0, math.min(state.height - 1, #args - 1) do
                state.data[y][x] = args[y + 1] as number
            end
        end,
        sort = function(self: Userdata)
            local state = internal_data[self]
            for x = 0, state.width - 1 do
                local column: {number} = {}
                for y = 0, state.height - 1 do
                    table.insert(column, state.data[y][x])
                end
                table.sort(column)
                for y = 0, state.height - 1 do
                    state.data[y][x] = column[y + 1]
                end
            end
        end,
    }
}


local pt_shim: Picotron = {
    menuitem = function(_id_or_item: integer | __MenuItem, _label: any, _action: any) end,
    sfx = function (_n: integer, _channel: integer, _offset: integer, _length: integer, _pan: integer, _mix_volume: integer) end,
    music = function(_n: integer, _fade_len: integer, _channel_mask: integer) end,
    note = function(_pitch: integer, _inst: integer, _vol: integer, _effect: integer, _effect_p: integer, _channel: integer, _retrig: boolean, _panning: integer) end,
    cocreate = coroutine.create,
    coresume = coroutine.resume,
    costatus = coroutine.status,
    yield = coroutine.yield,
    cd = function(_path: any) end,
    fstat = function(_path: any): (string | nil, number | nil, string | nil) return nil, nil, nil end,
    fullpath = function(filename: any): string return "/mock/" .. tostring(filename) end,
    ls = function(path: string): {string}
        local files: {string} = {}
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local f = path..'/'..file
                print("FOUND FILE: "..f.." "..file)
                table.insert(files, file)
            end
        end
        return files
    end,
    cp = function(_src: any, _dest: any) end,
    mv = function(_src: any, _dest: any) end,
    rm = function(_filename: any) end,
    pwd = function(): string return "/mock/" end,
    fetch = function(_filename: any): (any, __FileMetadata) return nil, nil end,
    store = function(_filename: string, _object: any, _metadata: __FileMetadata) end,
    fetch_metadata = function(_filename: string): __FileMetadata | nil return nil end,
    store_metadata = function(_filename: any, _metadata: __FileMetadata) end,
    mkdir = function(_name: any) end,
    mount = function(_target: string, _origin: string) end,
    include = function(path: string): any
        local trimmed_path = string.gsub(path, "%.lua", "")
        return require(trimmed_path)
    end,
    vid = function(_mode: integer) end,
    cls = function(_col: Color) end,
    print = function(value: string | integer, x: integer, y: integer, _col: Color): (integer, integer)
        return x + #tostring(value) * 4, y
    end,
    clip = function(_x: integer, _y: integer, _w: integer, _h: integer, _clip_previous: boolean) end,
    pset = function(_x: integer, _y: integer, _col: Color) end,
    pget = function(_x: integer, _y: integer): integer return 0 end,
    fget_one = function(_n: integer, _f: integer): boolean return false end,
    fget = function(_n: integer): integer return 0 end,
    fset = function(_n: integer, _f: integer, _val: boolean) end,
    cursor = function(_x: integer, _y: integer, _col: Color) end,
    set_color = function(_col: integer) end,
    reset_color = function() end,
    set_camera = function(_x: integer, _y: integer): (integer, integer) return 0, 0 end,
    reset_camera = function() end,
    circ = function(_x: integer, _y: integer, _r: integer, _col: Color) end,
    circfill = function(_x: integer, _y: integer, _r: integer, _col: Color) end,
    oval = function(_x0: integer, _y0: integer, _x1: integer, _y1: integer, _col: Color) end,
    ovalfill = function(_x0: integer, _y0: integer, _x1: integer, _y1: integer, _col: Color) end,
    line = function(_x0: integer, _y0: integer, _x1: integer, _y1: integer, _col: Color) end,
    rect = function(_x0: integer, _y0: integer, _x1: integer, _y1: integer, _col: Color) end,
    rrect = function(_x: integer, _y: integer, _w: integer, _h: integer, _radius: integer, _col: Color) end,
    rectfill = function(_x0: integer, _y0: integer, _x1: integer, _y1: integer, _col: Color) end,
    rrectfill = function(_x: integer, _y: integer, _w: integer, _h: integer, _radius: integer, _col: Color) end,
    set_pal = function(_c0: integer, _c1: integer, _p: integer) end,
    reset_pal = function() end,
    set_palt = function(_c: integer, _is_transparent: boolean) end,
    reset_palt = function(_c: integer) end,
    spr = function(_s: integer | Userdata, _x: number, _y: number, _flip_x: boolean, _flip_y: boolean) end,
    sspr = function(_s: integer | Userdata, _sx: integer, _sy: integer, _sw: integer, _sh: integer, _dx: integer, _dy: integer, _dw: integer, _dh: integer, _flip_x: boolean, _flip_y: boolean) end,
    fillp = function(...) local _ = {...} end,
    get_spr = function(_index: integer): Userdata return create_mock_userdata(8, 8) end, -- Return a default 8x8 userdata
    set_spr = function(_index: integer, _ud: Userdata) end,
    flip = function(_flags: integer) end,
    btn = function(_button: integer, _player: integer): boolean return false end,
    btnp = function(_button: integer, _player: integer): boolean return false end,
    key = function(_k: string, _raw: boolean): boolean return false end,
    keyp = function(_k: string, _raw: boolean): boolean return false end,
    clear_key = function(_k: string) end,
    peektext = function(): boolean return false end,
    readtext = function(_clear: boolean): string return "" end,
    get_mouse = function(): (number, number, integer, number, number) return 0, 0, 0, 0, 0 end,
    set_mouse = function(_new_mx: number, _new_my: number) end,
    mouselock = function(_lock: boolean, _event_sensitivity: number, _move_sensitivity: number): (number, number) return 0, 0 end,
    map = function(_src: any, _tile_x: any, _tile_y: any, _sx: any, _sy: any, _tiles_x: any, _tiles_y: any, _p8layers: any, _tile_w: any, _tile_h: any) end,
    mget = function(_x: any, _y: any): any return 0 end,
    mset = function(_x: any, _y: any, _val: any) end,
    tline3d = function(_src_ud: any, _x0: any, _y0: any, _x1: any, _y1: any, _u0: any, _v0: any, _u1: any, _v1: any, _w0: any, _w1: any, _flags: any) end,
    min = math.min,
    max = math.max,
    mid = function(x: integer, y: integer, z: integer): integer
        if x > y then x, y = y, x end
        if y > z then y, z = z, y end
        if x > y then x, y = y, x end
        return y
    end,
    flr = math.floor,
    ceil = math.ceil,
    rnd = function(limit: any): any
        if type(limit) == "table" then
            local tbl = limit as {any}
            return tbl[math.random(#tbl)]
        else
            return math.random() * (limit as number)
        end
    end,
    srand = math.randomseed,
    tonum = tonumber,
    abs = math.abs,
    absf = math.abs,
    sgn = function(n: number): integer
        if n > 0 then return 1
        elseif n < 0 then return -1
        else return 0
        end
    end,
    atan2 = function(dx: number, dy: number): Angle
        return math.atan2(dy, dx)
    end,
    sin = math.sin,
    cos = math.cos,
    sqrt = math.sqrt,
    peek = function(_addr: integer, _n: integer): integer return 0 end,
    peek2 = function(_addr: integer, _n: integer): integer return 0 end,
    peek4 = function(_addr: integer, _n: integer): integer return 0 end,
    peek8 = function(_addr: integer, _n: integer): integer return 0 end,
    poke = function(_addr: integer, ...) local _ = {...} end,
    poke2 = function(_addr: integer, ...) local _ = {...} end,
    poke4 = function(_addr: integer, ...) local _ = {...} end,
    poke8 = function(_addr: integer, ...) local _ = {...} end,
    memcpy = function(_dest_addr: integer, _source_addr: integer, _len: integer) end,
    memset = function(_dest_addr: integer, _val: integer, _len: integer) end,
    pod = function(val: any | string | Userdata | boolean | number, _flags: integer, _metadata: any): string | nil return tostring(val) end,
    unpod = function(val: string): (any | string | Userdata | boolean | number | nil, any) return val, nil end,
    chr = string.char,
    sub = string.sub,
    split = function(str: string, separator: string): {string}
        local result: {string} = {}
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
    type = type,
    env = function(): __Environment return {} as __Environment end,
    exit = function(_exit_code: integer) end,
    printh = print,
    create_process = function(_filename: string, _env: __Environment) end,
    stop = function(message: string) error(message or "stopped") end,
    time = function(): number return os.time() end,
    t = function(): number return os.time() end,
    date = function(format: string, t: integer | string, _delta: number): string return os.date(format, t as number) end,
    set_clipboard = function(_text: string) end,
    get_clipboard = function(): string return "" end,
    on_event = function(_event: string, _callback: any) end,
    send_message = function(_pid: integer, _event: any) end,
    pid = function(): integer return 1 end,
    notify = function(message: string) print("NOTIFY:", message) end,
    stat = function(_id: integer, _addr: integer) end,
    theme = function(_which: string) end,
    open = function(_file: string) end,
    add = function<V>(t: {V}, v: V, i: integer | nil)
		if i then
			table.insert(t, i, v)
		else
			table.insert(t, v)
		end
	end,
    del = function<V>(t: {V}, v: V): V | nil
        for i = #t, 1, -1 do
            if t[i] == v then
                return table.remove(t, i)
            end
        end
        return nil
    end,
    deli = table.remove,
    pop = function<V>(t: {V}): V | nil return table.remove(t) end,
    count = function(t: any, v: any): integer
        local tbl = t as {any}
        if v == nil then return #tbl end
        local c = 0
        for _, val in ipairs(tbl) do
            if val == v then
                c = c + 1
            end
        end
        return c
    end,
    all = function(t: any): function():any
        local i = 0
        local tbl = t as {any}
        return function(): any
            i = i + 1
            return tbl[i]
        end
    end,
    foreach = function(t: any, f: function(any))
        for _, v in ipairs(t as {any}) do
            f(v)
        end
    end,
    pack = function(...: any): any return table.pack(...) end,
    unpack = table.unpack,
    userdata = function(_data_type: userdata_type, width: integer, height: integer, _data: string): Userdata return create_mock_userdata(width, height) end,
    vec = function(...: number): Userdata
        local args = {...}
        local ud = create_mock_userdata(1, #args)
        local state = internal_data[ud]
        for i, v in ipairs(args) do
            state.data[i-1][0] = v
        end
        return ud
    end,
    get_display = function(): Userdata return create_mock_userdata(240, 136) end,
    set_draw_target = function(_ud: Userdata) end,
    get_draw_target = function(): Userdata return create_mock_userdata(240, 136) end,
    set_window_attributes = function(_attribs: __WindowAttribs) end,
    set_window_size = function(_width: integer, _height: integer, _attribs: __WindowAttribs) end,
    wrangle_working_file = function(_save_state: any, _load_state: any, _untitled_filename: string, _get_hlocation: any, _set_hlocation: any) end,
    pwf = function(): string | nil return nil end,
}

-- for calls within the engine
_G.pt = pt_shim

-- usable within mods.  Somewhat regrettably
local pt_map: {string: any} = pt_shim as {string: any}
for k,v in pairs(pt_map) do
    local _G_map: {string: any} = _G as {string: any} 
    if _G_map[k] == nil then
        _G_map[k] = v
    end
end
