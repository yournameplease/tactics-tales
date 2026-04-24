---@diagnostic disable: undefined-global
-- Usage: lua convert.lua [config.lua]
-- Run from the font's directory, e.g.:
--   cd fonts/kobold_7_v3 && lua ../font_converter/convert.lua config.lua

local script_dir = arg[0]:match("(.*[/\\])") or "./"
package.path = script_dir .. "?.lua;" .. package.path

local parse_meta   = require("parse_meta")
local read_pixels  = require("read_pixels")
local enc_glyphs   = require("encode_glyphs")
local enc_widths   = require("encode_widths")
local write_font   = require("write_font")

local config = dofile(arg[1] or "config.lua")

local char_widths  = parse_meta.parse(config.source_meta, config)
local glyphs       = read_pixels.read(config)
local bitmap_bytes = enc_glyphs.encode(glyphs, config)
local width_bytes  = enc_widths.encode(char_widths, config)

write_font.write(bitmap_bytes, width_bytes, config)
