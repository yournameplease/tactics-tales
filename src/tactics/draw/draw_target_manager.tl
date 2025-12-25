local interface DrawTargetManager
	push_target: function(self, w: integer, h: integer, c_x: integer, c_y: integer)
	draw: function(self, x: integer, y: integer)
end

local draw_target_manager = {
	DrawTargetManager = DrawTargetManager
}

local record DrawTargetEntry
	ud: Userdata
	camera_x: integer
	camera_y: integer
end

local record DrawTargetManagerImpl
	is DrawTargetManager
	targets: {DrawTargetEntry}
	current_target: DrawTargetEntry
end

function draw_target_manager.new(): DrawTargetManager
	local self: DrawTargetManagerImpl = setmetatable({},{
		__index = DrawTargetManagerImpl
	})
	return self
end

function DrawTargetManagerImpl:apply_current_target()
	if self.current_target ~= nil then
		pt.set_draw_target(self.current_target.ud)
	else
		pt.set_draw_target()
	end
end

function DrawTargetManagerImpl:push_target(w: integer, h: integer, c_x: integer, c_y: integer)
	local ud = pt.userdata("u8",w,h)
	self.current_target =  {
		ud = ud,
		camera_x = c_x or 0,
		camera_y = c_y or 0,
	}
	self:apply_current_target()
end

function DrawTargetManagerImpl:draw(x: integer, y: integer)
	assert(self.current_target ~= nil)
	pt.spr(self.current_target.ud, x, y)
	
	self:apply_current_target()
end

return draw_target_manager
