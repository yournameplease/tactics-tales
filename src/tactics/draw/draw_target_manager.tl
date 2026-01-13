require("profiler")
-- local colors = require("src/tactics/colors")

local interface DrawTargetManager
	push_target: function(self, w: integer, h: integer, d_x: integer, d_y: integer)
	duplicate_target: function(self)
	draw: function(self, x: integer, y: integer)
	pop_sprite: function(self): Userdata
end

local draw_target_manager = {
	DrawTargetManager = DrawTargetManager
}

local record DrawTargetEntry
	ud: Userdata
	w: integer
	h: integer
	camera_x: integer
	camera_y: integer
end

local record DrawTargetManagerImpl
	is DrawTargetManager
	targets: {DrawTargetEntry}
	current_target: DrawTargetEntry
end

function DrawTargetManagerImpl:apply_current_target()
	if self.current_target ~= nil then
		pt.set_draw_target(self.current_target.ud)
		pt.set_camera(self.current_target.camera_x, self.current_target.camera_y)
	else
		pt.set_draw_target()
		pt.reset_camera()
	end
end

function DrawTargetManagerImpl:push_target(w: integer, h: integer, d_x: integer, d_y: integer)
	profile("draw_target_manager_push")
	local ud = pt.userdata("u8",w,h)
	local new_target =  {
		ud = ud,
		w = w,
		h = h,
		camera_x = -d_x or 0,
		camera_y = -d_y or 0,
	}

	if self.current_target ~= nil then
		pt.add(self.targets, self.current_target)
	end
	self.current_target = new_target
	self:apply_current_target()
	if true then
		-- local color = colors.rainbow(#self.targets)	
		-- pt.rrectfill(d_x, d_y, w, h, 0, color[2])
	end
	profile("draw_target_manager_push")
end

function DrawTargetManagerImpl:duplicate_target()
	self:push_target(
		self.current_target.w,
		self.current_target.h,
		-- 0, 0
		-self.current_target.camera_x,
		-self.current_target.camera_y
	)
end

function DrawTargetManagerImpl:draw(x: integer, y: integer)
	profile("draw_target_manager_draw")
	assert(self.current_target ~= nil)
	local prev_target = self.current_target
	self.current_target = pt.pop(self.targets)
	self:apply_current_target()
	
	-- pt.sspr(prev_target.ud, 0, 0, prev_target.w, prev_target.h, x, y)	
	pt.spr(prev_target.ud, x, y)
	if true then
		-- local color = colors.rainbow(#self.targets + (self.current_target == nil and 0 or 1))
		-- pt.rrect(x, y, prev_target.w, prev_target.h, 0, color[1])
	end
	profile("draw_target_manager_draw")
end

function DrawTargetManagerImpl:pop_sprite(): Userdata
	assert(self.current_target ~= nil)
	local prev_target = self.current_target
	self.current_target = pt.pop(self.targets)
	self:apply_current_target()

	-- log.debug("popping sprite", prev_target.ud)
	-- for x = 0, prev_target.ud:width() - 1 do
	-- 	local out = ""
	-- 	for y = 0, prev_target.ud:height() - 1 do
	-- 		out = out .. tostring(prev_target.ud:get(x as integer,y as integer)).."|"
	-- 	end
	-- 	pt.printh(out)
	-- end
	return prev_target.ud
end

function draw_target_manager.new(): DrawTargetManager
	local self: DrawTargetManagerImpl = setmetatable({},{
		__index = DrawTargetManagerImpl
	})
	self.targets = {}
	return self
end

return draw_target_manager
