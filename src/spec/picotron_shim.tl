-- AI generated.  I disabled/fixed broken things but have not looked closely

-- This file shims the Picotron API for testing in a standard Lua environment.

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
-- _G.DYNAMIC_CONFIG = {
--     log_level = "DEBUG",
--     draw_flexbox_debug = false,
--     draw_target_debug = false,
--     head_scale = 1,
--     dialogue_speed = "normal",
-- }
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

local pt_shim: Picotron = {
    menuitem = function(id_or_item: integer | __MenuItem, label: any, action: any) end,
    sfx = function (n: integer, channel: integer, offset: integer, length: integer, pan: integer, mix_volume: integer) end,
    music = function(n: integer, fade_len: integer, channel_mask: integer) end,
    note = function(pitch: integer, inst: integer, vol: integer, effect: integer, effect_p: integer, channel: integer, retrig: boolean, panning: integer) end,
    cocreate = coroutine.create,
    coresume = coroutine.resume,
    costatus = coroutine.status,
    yield = coroutine.yield,
    cd = function(path: any) end,
    fstat = function(path: any): (string | nil, number | nil, string | nil) return nil, nil, nil end,
    fullpath = function(filename: any): string return "/mock/" .. tostring(filename) end,
    ls = function(path: any): {string} return {} end,
    cp = function(src: any, dest: any) end,
    mv = function(src: any, dest: any) end,
    rm = function(filename: any) end,
    pwd = function(): string return "/mock/" end,
    fetch = function(filename: any): (any, __FileMetadata) return nil, nil end,
    store = function(filename: string, object: any, metadata: __FileMetadata) end,
    fetch_metadata = function(filename: string): __FileMetadata | nil return nil end,
    store_metadata = function(filename: any, metadata: __FileMetadata) end,
    mkdir = function(name: any) end,
    mount = function(target: string, origin: string) end,
    include = require,
    vid = function(mode: integer) end,
    cls = function(col: Color) end,
    print = function(value: string | integer, x: integer, y: integer, col: Color): (integer, integer)
        return x + #tostring(value) * 4, y
    end,
    clip = function(x: integer, y: integer, w: integer, h: integer, clip_previous: boolean) end,
    pset = function(x: integer, y: integer, col: Color) end,
    pget = function(x: integer, y: integer): integer return 0 end,
    fget_one = function(n: integer, f: integer): boolean return false end,
    fget = function(n: integer): integer return 0 end,
    fset = function(n: integer, f: integer, val: boolean) end,
    cursor = function(x: integer, y: integer, col: Color) end,
    set_color = function(col: integer) end,
    reset_color = function() end,
    set_camera = function(x: integer, y: integer): (integer, integer) return 0, 0 end,
    reset_camera = function() end,
    circ = function(x: integer, y: integer, r: integer, col: Color) end,
    circfill = function(x: integer, y: integer, r: integer, col: Color) end,
    oval = function(x0: integer, y0: integer, x1: integer, y1: integer, col: Color) end,
    ovalfill = function(x0: integer, y0: integer, x1: integer, y1: integer, col: Color) end,
    line = function(x0: integer, y0: integer, x1: integer, y1: integer, col: Color) end,
    rect = function(x0: integer, y0: integer, x1: integer, y1: integer, col: Color) end,
    rrect = function(x: integer, y: integer, w: integer, h: integer, radius: integer, col: Color) end,
    rectfill = function(x0: integer, y0: integer, x1: integer, y1: integer, col: Color) end,
    rrectfill = function(x: integer, y: integer, w: integer, h: integer, radius: integer, col: Color) end,
    set_pal = function(c0: integer, c1: integer, p: integer) end,
    reset_pal = function() end,
    set_palt = function(c: integer, is_transparent: boolean) end,
    reset_palt = function(c: integer) end,
    spr = function(s: integer | Userdata, x: number, y: number, flip_x: boolean, flip_y: boolean) end,
    sspr = function(s: integer | Userdata, sx: integer, sy: integer, sw: integer, sh: integer, dx: integer, dy: integer, dw: integer, dh: integer, flip_x: boolean, flip_y: boolean) end,
    fillp = function(...) end,
    get_spr = function(index: integer): Userdata return nil end,
    set_spr = function(index: integer, ud: Userdata) end,
    flip = function(flags: integer) end,
    btn = function(button: integer, player: integer): boolean return false end,
    btnp = function(button: integer, player: integer): boolean return false end,
    key = function(k: string, raw: boolean): boolean return false end,
    keyp = function(k: string, raw: boolean): boolean return false end,
    clear_key = function(k: string) end,
    peektext = function(): boolean return false end,
    readtext = function(clear: boolean): string return "" end,
    get_mouse = function(): (number, number, integer, number, number) return 0, 0, 0, 0, 0 end,
    set_mouse = function(new_mx: number, new_my: number) end,
    mouselock = function(lock: boolean, event_sensitivity: number, move_sensitivity: number): (number, number) return 0, 0 end,
    map = function(src: any, tile_x: any, tile_y: any, sx: any, sy: any, tiles_x: any, tiles_y: any, p8layers: any, tile_w: any, tile_h: any) end,
    mget = function(x: any, y: any): any return 0 end,
    mset = function(x: any, y: any, val: any) end,
    tline3d = function(src_ud: any, x0: any, y0: any, x1: any, y1: any, u0: any, v0: any, u1: any, v1: any, w0: any, w1: any, flags: any) end,
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
            local tab: {string: any} = limit as {string: any}
            for _,v in pairs(tab) do
                return v
            end
            return nil
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
    peek = function(addr: integer, n: integer): integer return 0 end,
    peek2 = function(addr: integer, n: integer): integer return 0 end,
    peek4 = function(addr: integer, n: integer): integer return 0 end,
    peek8 = function(addr: integer, n: integer): integer return 0 end,
    poke = function(addr: integer, ...) end,
    poke2 = function(addr: integer, ...) end,
    poke4 = function(addr: integer, ...) end,
    poke8 = function(addr: integer, ...) end,
    memcpy = function(dest_addr: integer, source_addr: integer, len: integer) end,
    memset = function(dest_addr: integer, val: integer, len: integer) end,
    pod = function(val: any | string | Userdata | boolean | number, flags: integer, metadata: any): string | nil return tostring(val) end,
    unpod = function(val: string): (any | string | Userdata | boolean | number | nil, any) return val, nil end,
    chr = string.char,
    sub = string.sub,
    split = function(str: string, separator: string): {string}
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
    type = type,
    env = function(): __Environment return {} as __Environment end,
    exit = function(exit_code: integer) end,
    printh = print,
    create_process = function(filename: string, env: __Environment) end,
    stop = function(message: string) error(message or "stopped") end,
    time = function(): number return os.time() end,
    t = function(): number return os.time() end,
    date = function(format: string, t: integer | string, delta: number): string return os.date(format, t as number) end,
    set_clipboard = function(text: string) end,
    get_clipboard = function(): string return "" end,
    on_event = function(event: string, callback: any) end,
    send_message = function(pid: integer, event: any) end,
    pid = function(): integer return 1 end,
    notify = function(message: string) print("NOTIFY:", message) end,
    stat = function(id: integer, addr: integer) end,
    theme = function(which: string) end,
    open = function(file: string) end,
    add = function<V>(t: {V}, v: V, i: integer) table.insert(t, i, v) end,
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
        if v == nil then return #(t as {any}) end
        local c = 0
        for _, val in ipairs(t as {any}) do
            if val == v then
                c = c + 1
            end
        end
        return c
    end,
    all = function(t: any): function():any
        local i = 0
        return function(): any
            i = i + 1
            return (t as {any})[i]
        end
    end,
    -- foreach = function(t: any, f: function())
    --     for _, v in ipairs(t as {any}) do
    --         f(v)
    --     end
    -- end,
    -- pack = table.pack,
    unpack = table.unpack,
    userdata = function(data_type: userdata_type, width: integer, height: integer, data: string): Userdata return {} as Userdata end,
    vec = function(...: number): Userdata return {...} as Userdata end,
    get_display = function(): Userdata return nil end,
    set_draw_target = function(ud: Userdata) end,
    get_draw_target = function(): Userdata return nil end,
    set_window_attributes = function(attribs: __WindowAttribs) end,
    set_window_size = function(width: integer, height: integer, attribs: __WindowAttribs) end,
    wrangle_working_file = function(save_state: any, load_state: any, untitled_filename: string, get_hlocation: any, set_hlocation: any) end,
    pwf = function(): string | nil return nil end,
}

_G.pt = pt_shim
