global todo: function(message?: string): any
global unexpected: function(state: string)

-- nice utility types
global type Angle = number
global type Color = integer

--- @class __MenuItem
--- @field id? integer Unique identifier, used to sort items (otherwise order added is used)
--- @field label? string | function User facing label
--- @field shortcut? string Drawn right justified in the menu
--- @field greyed? boolean Greyed out item (use for ---)
--- @field action? function Callback on select -- param b is the button pressed (left or right)
--- @field divider? boolean Is item a divider
global record __MenuItem
	id: integer 
	label: string 
	shortcut: string 
	greyed: boolean 
	action: function 
	divider: boolean 	
end

--- @class __FileMetadata
--- @field created string
--- @field modified string
--- @field pod_format? string
--- @field revision? integer
global record __FileMetadata
	created: string
	modified: string
	pod_format: string
	revision: integer
end

global DATP: string

--- Environment Properties
--- @class __Environment
--- @field argv? string[]
--- @field immortal? boolean
--- @field parent_pid? integer
--- @field path? string
--- @field print_to_proc_id? integer
--- @field prog_name? string
--- @field title? string
--- @field window_attribs? __WindowAttribs
global record __Environment 
	argv: {string}
	immortal: boolean
	parent_pid: integer
	path: string
	print_to_proc_id: integer
	prog_name: string
	title: string
	window_attribs: __WindowAttribs
end


--- @class userdata
--- @field x number
--- @field y number
--- @field z number
--- @operator add(userdata|number):userdata
--- @operator sub(userdata|number):userdata
--- @operator mul(userdata|number):userdata
--- @operator div(userdata|number):userdata
global record Userdata
	x: number
	y: number
	z: number
	width: function(self): integer | nil
	height: function(self): integer | nil
	get: function(self, integer, integer): integer
	set: function(self, integer, ...: integer)
	sort: function(self)
end


global enum userdata_type
	"u8"
	"i16"
	"i32"
	"i64"
	"f64"
end

--- Window Attributes
--- @class __WindowAttribs
--- @field autoclose? boolean
--- @field cursor? 0 | 1 | string | userdata
--- @field fullscreen? boolean
--- @field has_frame? boolean
--- @field height? integer
--- @field immortal? boolean
--- @field moveable? boolean
--- @field pausable? boolean
--- @field pwc_output? boolean
--- @field resizable? boolean
--- @field show_in_workspace? boolean
--- @field tabbed? boolean
--- @field title? string
--- @field video_mode? 0 | 3 | 4
--- @field wallpaper? boolean
--- @field width? integer
--- @field x? integer
--- @field y? integer
--- @field z? integer
global record __WindowAttribs
	autoclose: boolean
	cursor: integer | string | Userdata
	fullscreen: boolean
	has_frame: boolean
	height: integer
	immortal: boolean
	moveable: boolean
	pausable: boolean
	pwc_output: boolean
	resizable: boolean
	show_in_workspace: boolean
	tabbed: boolean
	title: string
	video_mode: integer
	wallpaper: boolean
	width: integer
	x: integer
	y: integer
	z: integer
end

global _init: function()
global _update: function()
global _draw: function()


global record Picotron
	-- menuitem: function(m?: __MenuItem) 
	menuitem: function(id?: integer | __MenuItem, label?: any, action?: any) 
	sfx: function (n: integer, channel?: integer, offset?: integer, length?: integer, pan?: integer, mix_volume?: integer) 
	music: function(n: integer, fade_len?: integer, channel_mask?: integer) 
	note: function(pitch: integer, inst: integer, vol: integer, effect: integer, effect_p: integer, channel: integer, retrig: boolean, panning: integer) 
	_init: function()
	_update: function()
	_draw: function()
	cocreate: function(func: any): any
	coresume: function(c: any, ...: any): boolean, string
	costatus: function(c: any) : string
	yield: function(...: any) 
	cd: function(path: any) 
	fstat: function(path: any): string | nil, number | nil, string | nil 
	fullpath: function(filename: any) : string
	ls: function(path?: any) : {string}
	cp: function(src: any, dest: any) 
	mv: function(src: any, dest: any) 
	rm: function(filename: any) 
	pwd: function(): string
	fetch: function(filename: any): any, __FileMetadata
	store: function(filename: string, object: any, metadata: __FileMetadata) 
	fetch_metadata: function(filename: string): __FileMetadata | nil
	store_metadata: function(filename: any, metadata: __FileMetadata) 
	mkdir: function(name: any) 
	mount: function(target: string, origin: string) 
	include: function(filename: string) : any
	vid: function(mode: integer) 
	cls: function(col?: Color) 
	print: function(value: string | integer, x: integer, y: integer, col?: Color): integer, integer
	clip: function(x: integer, y: integer, w: integer, h: integer, clip_previous?: boolean) 
	-- clip: function(): integer, integer, integer, integer 
	pset: function(x: integer, y: integer, col?: Color) 
	pget: function(x: integer, y: integer) : integer
	-- fget: function(n: integer, f: integer) : boolean
	fget_one: function(n: integer, f: integer) : boolean
	fget: function(n: integer) : integer
	fset: function(n: integer, f: integer, val: boolean) 
	cursor: function(x: integer, y: integer, col?: Color) 
	set_color: function(col: integer) 
	reset_color: function() 
	set_camera: function(x: integer, y: integer) : integer, integer
	reset_camera: function()
	-- camera: function()
	circ: function(x: integer, y: integer, r: integer, col?: Color) 
	circfill: function(x: integer, y: integer, r: integer, col?: Color) 
	oval: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: Color) 
	ovalfill: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: Color) 
	line: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: Color) 
	-- line: function()  
	rect: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: Color) 
	rrect: function(x: integer, y: integer, w: integer, h: integer, radius?: integer, col?: Color) 
	rectfill: function(x0: integer, y0: integer, x1: integer, y1: integer, col?: Color) 
	rrectfill: function(x: integer, y: integer, w: integer, h: integer, radius?: integer, col?: Color) 
	set_pal: function(c0: integer, c1: integer, p?: integer) 
	reset_pal: function() 
	-- pal: function(c0: integer, argb: integer, p: integer) 
	-- pal: function(p: integer) 
	-- pal: function(p: integer) 
	-- pal: function()  
	set_palt: function(c: integer, is_transparent: boolean) 
	reset_palt: function(c?: integer) 
	-- palt: function(c: integer) 
	spr: function(s: integer | Userdata, x?: number, y?: number, flip_x?: boolean, flip_y?: boolean) 
	sspr: function(s: integer | Userdata, sx?: integer, sy?: integer, sw?: integer, sh?: integer, dx?: integer, dy?: integer, dw?: integer, dh?: integer, flip_x?: boolean, flip_y?: boolean) 
	-- fillp: function(p?: integer, ...: integer) 
	fillp: function(...: any) 
	get_spr: function(index: integer) : Userdata
	set_spr: function(index: integer, ud: Userdata) 
	flip: function(flags?: integer) 
	-- create_gui: function(head_el: any) 
	-- btn: function(button: integer, player?: integer) : number | boolean
	btn: function(button: integer, player?: integer) : boolean
	-- btnp: function(button: integer, player?: integer): number | boolean 
	btnp: function(button: integer, player?: integer): boolean 
	key: function(k: string, raw?: boolean) : boolean
	keyp: function(k: string, raw?: boolean): boolean 
	clear_key: function(k: string) 
	peektext: function(): boolean
	readtext: function(clear?: boolean) 
	get_mouse: function(): number, number, integer, number, number 
	set_mouse: function(new_mx: number, new_my: number)  
	mouselock: function(lock: boolean, event_sensitivity: number, move_sensitivity: number): number, number 
	-- map: function(tile_x: any, tile_y: any, sx: any, sy: any, tiles_x: any, tiles_y: any, p8layers: any, tile_w: any, tile_h: any) 
	map: function(src: any, tile_x: any, tile_y: any, sx?: any, sy?: any, tiles_x?: any, tiles_y?: any, p8layers?: any, tile_w?: any, tile_h?: any) 
	mget: function(x: any, y: any) 
	mset: function(x: any, y: any, val: any) 
	tline3d: function(src_ud: any, x0: any, y0: any, x1: any, y1: any, u0: any, v0: any, u1: any, v1: any, w0: any, w1: any, flags: any) 
	-- min: function(x: number, y: number) : number
	min: function(x: integer, y: integer) : integer
	-- max: function(x: number, y: number) : number
	max: function(x: integer, y: integer) : integer
	-- mid: function(x: number, y: number, z: number) : number
	mid: function(x: integer, y: integer, z: integer) : integer
	flr: function(x: number) : integer
	ceil: function(val: number) : integer
	rnd: function(limit: number) : number
	-- rnd: function(tbl: number) : any
	srand: function(val: number) : number
	tonum: function(val: any, format_flags: integer) : number
	-- abs: function(n: number) : number
	abs: function(n: integer) : integer
	absf: function(n: number) : number
	sgn: function(n: number) : integer
	atan2: function(dx: number, dy: number) : Angle
	sin: function(angle: Angle) : number
	cos: function(angle: Angle) : number
	sqrt: function(n: number) : number
	peek: function(addr: integer, n?: integer): integer
	peek2: function(addr: integer, n?: integer): integer
	peek4: function(addr: integer, n?: integer): integer
	peek8: function(addr: integer, n?: integer): integer
	poke: function(addr: integer, ...: integer)
	poke2: function(addr: integer, ...: integer)
	poke4: function(addr: integer, ...: integer)
	poke8: function(addr: integer, ...: integer)
	memcpy: function(dest_addr: integer, source_addr: integer, len: integer) 
	memset: function(dest_addr: integer, val: integer, len: integer) 
	pod: function(val: any | string | Userdata | boolean | number, flags?: integer, metadata?: any): string | nil 
	unpod: function(val: string): any | string | Userdata | boolean | number | nil, any
	-- socket: function(addr: any) 
	-- chr: function(val: any, ...: any) 
	chr: function(val: integer): string 
	-- ord: function(str: any, index: any, num_results: any) 
	sub: function(str: string, pos0: integer, pos1: integer | boolean): string 
	-- tostr: function(value: any, as_hex: any) 
	-- split: function(str: any, separator: any, convert_numbers: any) 
	-- split: function(str: any, separator: any, convert_numbers: any) 
	-- create_delta: function(str0: any, str1: any) 
	-- apply_delta: function(str0: any, delta: any) 
	env: function() : __Environment 
	exit: function(exit_code?: integer) 
	printh: function(value: any) 
	create_process: function(filename: string, env?: __Environment) 
	stop: function(message?: string) 
	-- assert: function(condition: boolean, message: string) 
	time: function() : number
	t : function() : number
	date: function(format?: string, t?: integer | string, delta?: number): string 
	set_clipboard: function(text: string) 
	get_clipboard: function(): string 
	on_event: function(event: string, callback: any) 
	send_message: function(pid: integer, event: any) 
	pid: function() : integer 
	notify: function(message: string) 
	stat: function(id?: integer, addr?: integer) 
	theme: function(which: string) 
	open: function(file: string) 

	-- tables
	add: function<V>(table: {V}, value: V, index?: integer) 
	del: function<V>(table: {V}, value: V): V | nil
	deli: function<V>(table: {V}, index: integer): V | nil
	pop: function<V>(table: {V}): V | nil

	count: function(table: any, value?: any) 
	all: function(table: any) : any
	foreach: function(table: any, func: any) 
	pack: function(...: any)  
	unpack: function(tbl: any) : any
		width: function(self): integer | nil
		height: function(self): integer | nil
		get: function(self, integer, integer): integer
		set: function(self, integer, ...: integer)
		sort: function(self)
	userdata: function(data_type: userdata_type, width: integer, height: integer, data?: string): Userdata 
	vec: function(...: number) : Userdata 
	-- get: function(u: any, x: any, y: any, n: any) 
	-- set: function(u: any, x: any, ...: any) 
	-- set: function(u: any, x: any, y: any, ...: any) 
	-- blit: function(src: any, dest: any, src_x: any, src_y: any, dest_x: any, dest_y: any, width: any, height: any) 
	-- memmap: function(ud: any, addr: any) 
	-- unmap: function(ud: any, addr: any) 
	get_display: function() : Userdata 
	set_draw_target: function(ud?: Userdata) 
	get_draw_target: function(): Userdata 
	set_window_attributes: function(attribs: __WindowAttribs) 
	set_window_size: function(width: integer, height: integer, attribs?: __WindowAttribs) 
	-- window: function(attribs: __WindowAttribs) 
	wrangle_working_file: function(save_state?: any, load_state?: any, untitled_filename?: string, get_hlocation?: any, set_hlocation?: any) 
	pwf: function() : string | nil 
end

global pt: Picotron
