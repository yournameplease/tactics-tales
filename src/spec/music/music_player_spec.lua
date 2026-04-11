require("spec/picotron_shim")
local luassert = require("luassert")
local music_player = require("tactics/music/music_player")

describe("tactics.music.music_player", function()
    local player
    local music_calls
    local original_music
    local original_stat

    before_each(function()
        player = music_player.new()
        music_calls = {}
        original_music = pt.music
        original_stat = pt.stat
        pt.music = function(n, fade_len, _ch_mask, _base_addr, offset)
            table.insert(music_calls, { n = n, fade_len = fade_len, offset = offset })
        end
    end)

    after_each(function()
        pt.music = original_music
        pt.stat = original_stat
    end)

    describe("new", function()
        it("should initialise current_track to -1", function()
            luassert.are_equal(-1, player.current_track)
        end)
    end)

    describe("set_music", function()
        it("should call pt.music with the given track and offset", function()
            player:set_music(3, 12)
            luassert.are_equal(1, #music_calls)
            luassert.are_equal(3, music_calls[1].n)
            luassert.are_equal(12, music_calls[1].offset)
        end)

        it("should update current_track", function()
            player:set_music(5, 0)
            luassert.are_equal(5, player.current_track)
        end)
    end)

    describe("push_music", function()
        it("should call pt.music with the new track and offset", function()
            pt.stat = function(_) return 0 end
            player:push_music(7, 4)
            luassert.are_equal(1, #music_calls)
            luassert.are_equal(7, music_calls[1].n)
            luassert.are_equal(4, music_calls[1].offset)
        end)

        it("should save the current playback position from pt.stat(466)", function()
            pt.stat = function(id)
                if id == 466 then return 42 end
            end
            player:push_music(2, 0)
            luassert.are_equal(42, player.current_offset)
        end)
    end)

    describe("resume_music", function()
        it("should call pt.music with the saved track, fade_time, and saved offset", function()
            player.current_track = 3
            player.current_offset = 99
            player:resume_music(30)
            luassert.are_equal(1, #music_calls)
            luassert.are_equal(3, music_calls[1].n)
            luassert.are_equal(30, music_calls[1].fade_len)
            luassert.are_equal(99, music_calls[1].offset)
        end)
    end)

    describe("clear_music", function()
        it("should call pt.music with track -1", function()
            player:clear_music()
            luassert.are_equal(1, #music_calls)
            luassert.are_equal(-1, music_calls[1].n)
        end)
    end)
end)
