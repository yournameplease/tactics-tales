---@brief Manages playback of music tracks, including push/resume for temporary track interruptions.

---@class MusicPlayer
---@field package current_track integer The track index currently playing (-1 if none).
---@field package current_offset integer The saved playback offset for resume after push.
local MusicPlayer = {}
MusicPlayer.__index = MusicPlayer

local music_player = {}

--- Create and return a new MusicPlayer.
---@return MusicPlayer
function music_player.new()
    local self = setmetatable({}, MusicPlayer)
    self.current_track = -1
    self.current_offset = 0
    return self
end

--- Start playing a track from the given offset.
---@param track integer
---@param offset integer
function MusicPlayer:set_music(track, offset)
    self.current_track = track
    pt.music(track, nil, nil, nil, offset)
end

--- Play a new track, saving the current playback position for later resume.
---@param track integer
---@param offset integer
function MusicPlayer:push_music(track, offset)
    self.current_offset = pt.stat(466) or 0
    pt.music(track, nil, nil, nil, offset)
end

--- Resume the previously playing track at its saved offset.
---@param fade_time integer
function MusicPlayer:resume_music(fade_time)
    pt.music(self.current_track, fade_time, nil, nil, self.current_offset)
end

--- Stop all music.
function MusicPlayer:clear_music()
    pt.music(-1, nil, nil, nil, nil)
end

return music_player
