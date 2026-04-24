---@diagnostic disable: undefined-global
local M = {}

local function utf8_seq_len(b)
  if b >= 0xF0 then return 4
  elseif b >= 0xE0 then return 3
  elseif b >= 0xC0 then return 2
  else return 1
  end
end

local function utf8_chars(s, fn)
  local i = 1
  while i <= #s do
    local b = s:byte(i)
    local len = utf8_seq_len(b)
    fn(s:sub(i, i + len - 1))
    i = i + len
  end
end

local function build_sheet_index(sheet_chars)
  local index = {}
  local pos = 0
  utf8_chars(sheet_chars, function(ch)
    index[ch] = pos
    pos = pos + 1
  end)
  return index
end

function M.read(config)
  local png = config.source_png
  local bw = config.base_width
  local bh = config.height
  local sx = config.slice_x_offset or 0
  local sy = config.slice_y_offset or 0
  local SLICE = 8

  local handle = io.popen(string.format("magick identify -format '%%w %%h' %q", png))
  local dims = handle:read("*l")
  handle:close()
  local img_w = tonumber(dims:match("(%d+)"))
  local cols = math.floor(img_w / bw)

  local rgba_path = "/tmp/font_raw_" .. os.time() .. ".rgba"
  os.execute(string.format("magick %q rgba:%q", png, rgba_path))

  local f = assert(io.open(rgba_path, "rb"), "Cannot open RGBA dump: " .. rgba_path)
  local raw = f:read("*a")
  f:close()
  os.remove(rgba_path)

  local function get_alpha(px, py)
    -- raw is 1-indexed; each pixel = 4 bytes; alpha is byte 4
    local offset = (py * img_w + px) * 4 + 4
    return raw:byte(offset) or 0
  end

  local dh = config.descender_height or 0
  local descender_set = {}
  if config.descender_chars then
    utf8_chars(config.descender_chars, function(ch) descender_set[ch] = true end)
  end

  local sheet_index = build_sheet_index(config.sheet_chars)
  local glyphs = {}

  utf8_chars(config.p8_chars, function(ch)
    local idx = sheet_index[ch]
    if idx == nil then
      io.stderr:write(string.format("Warning: %q not in sheet_chars, using blank glyph\n", ch))
      local pixels = {}
      for y = 0, SLICE - 1 do
        pixels[y] = {}
        for x = 0, SLICE - 1 do pixels[y][x] = false end
      end
      glyphs[ch] = pixels
      return
    end

    local sheet_col = idx % cols
    local sheet_row = math.floor(idx / cols)
    local px0 = sheet_col * bw
    local py0 = sheet_row * bh
    local eff_sy = descender_set[ch] and (sy + dh) or sy

    local pixels = {}
    for y = 0, SLICE - 1 do
      pixels[y] = {}
      for x = 0, SLICE - 1 do
        pixels[y][x] = get_alpha(px0 + sx + x, py0 + eff_sy + y) > 0
      end
    end
    glyphs[ch] = pixels
  end)

  return glyphs
end

return M
