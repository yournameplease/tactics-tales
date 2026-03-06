

local interface MusicPlayer
	set_music: function(self, track: integer, offset: integer)
	push_music: function(self, track: integer, offset: integer)
	resume_music: function(self, fade_time: integer)
	clear_music: function(self)
end

local music_player = {
	MusicPlayer = MusicPlayer,
}

local record MusicPlayerImpl
	is MusicPlayer

	current_track: integer
	current_offset: integer
end

function music_player.new(): MusicPlayer
	local self: MusicPlayerImpl = setmetatable({},{
		__index = MusicPlayerImpl
	})

	self.current_track = -1

	return self
end

function MusicPlayerImpl:set_music(track: integer, offset: integer)
	self.current_track = track

	pt.music(track, nil, nil, nil, offset)
end

function MusicPlayerImpl:push_music(track: integer, offset: integer)
	self.current_offset = pt.stat(466) as integer
	
	pt.music(track, nil, nil, nil, offset)
end

function MusicPlayerImpl:resume_music(fade_time: integer)
	pt.music(self.current_track, fade_time, nil, nil, self.current_offset)
end

function MusicPlayerImpl:clear_music()
	pt.music(-1, nil, nil, nil, nil)
end

return music_player
