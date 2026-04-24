-- Usage: lua preview_font.lua <file.font> [num_glyphs]
local path = arg[1] or error("Usage: lua preview_font.lua <file.font> [num_glyphs]")

local f = assert(io.open(path, "r"))
local content = f:read("*a")
f:close()

local hex = content:match('hex:([0-9a-fA-F]+)"')
assert(hex, "no hex data found in " .. path)

local bytes = {}
for i = 1, #hex, 2 do
  bytes[#bytes + 1] = tonumber(hex:sub(i, i + 1), 16)
end

local glyph_w = bytes[1]
local glyph_h = bytes[2]
local HEADER         = 8
local COLS           = 16
local bytes_per_glyph = math.ceil(glyph_w / 8) * glyph_h
local num_glyphs      = tonumber(arg[2]) or 95  -- default: ASCII 32-126
local BITMAP_OFFSET   = HEADER + num_glyphs      -- width hints precede bitmap

io.write(string.format("glyph %dx%d  glyphs=%d  bytes_per_glyph=%d\n\n",
  glyph_w, glyph_h, num_glyphs, bytes_per_glyph))

local function glyph_rows(idx)
  local base = BITMAP_OFFSET + idx * bytes_per_glyph
  local rows = {}
  for row = 0, glyph_h - 1 do
    local byte_idx = base + math.floor(row * math.ceil(glyph_w / 8))
    local b = bytes[byte_idx + 1] or 0
    local line = {}
    for bit = 0, glyph_w - 1 do
      line[#line + 1] = ((b & (1 << bit)) ~= 0) and "█" or "░"
    end
    rows[#rows + 1] = table.concat(line)
  end
  return rows
end

for block_start = 0, num_glyphs - 1, COLS do
  -- character labels (ASCII 32+ assumed)
  local labels = {}
  for col = 0, COLS - 1 do
    local idx = block_start + col
    if idx >= num_glyphs then break end
    local ch = (idx + 32 >= 33 and idx + 32 <= 126)
               and string.char(idx + 32) or "·"
    labels[#labels + 1] = string.format("%-" .. (glyph_w + 1) .. "s", ch)
  end
  print(table.concat(labels))

  -- pixel rows
  local rendered = {}
  for col = 0, COLS - 1 do
    local idx = block_start + col
    if idx < num_glyphs then rendered[col] = glyph_rows(idx) end
  end
  for row = 1, glyph_h do
    local line = {}
    for col = 0, COLS - 1 do
      if rendered[col] then
        line[#line + 1] = rendered[col][row]
        line[#line + 1] = " "
      end
    end
    print(table.concat(line))
  end
  print()
end
