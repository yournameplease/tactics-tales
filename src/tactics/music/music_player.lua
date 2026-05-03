---@brief Manages playback of music tracks, including push/resume for temporary track interruptions.

---@class MusicPlayer
---@field package current_track integer The track index currently playing (-1 if none).
---@field package current_offset integer The saved playback offset for resume after push.
local MusicPlayer = {}
MusicPlayer.__index = MusicPlayer

local music_player = {}

---@return integer The current music volume, from 0 - 100%
local function current_music_volume()
    return DYNAMIC_CONFIG.music_volume * DYNAMIC_CONFIG.master_volume
end

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
    if current_music_volume() > 0 then
        music(track, nil, nil, nil, offset)
    end
end

--- Play a new track, saving the current playback position for later resume.
---@param track integer
---@param offset integer
function MusicPlayer:push_music(track, offset)
    self.current_offset = stat(466) or 0
    if current_music_volume() > 0 then
        music(track, nil, nil, nil, offset)
    end
end

--- Resume the previously playing track at its saved offset.
---@param fade_time integer
function MusicPlayer:resume_music(fade_time)
    if current_music_volume() > 0 then
        music(self.current_track, fade_time, nil, nil, self.current_offset)
    end
end

--- Stop all music.
function MusicPlayer:clear_music()
    music(-1, nil, nil, nil, nil)
end

return music_player
