local interface DrawTargetManager
	push_target: function(self, w: integer, h: integer, d_x: integer, d_y: integer)
	draw: function(self, x: integer, y: integer)
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
end

function DrawTargetManagerImpl:draw(x: integer, y: integer)
	assert(self.current_target ~= nil)
	local prev_target = self.current_target
	self.current_target = pt.pop(self.targets)
	self:apply_current_target()
	
	-- pt.sspr(prev_target.ud, 0, 0, prev_target.w, prev_target.h, x, y)	
	pt.spr(prev_target.ud, x, y)	

end

function draw_target_manager.new(): DrawTargetManager
	local self: DrawTargetManagerImpl = setmetatable({},{
		__index = DrawTargetManagerImpl
	})
	self.targets = {}
	return self
end

return draw_target_manager
