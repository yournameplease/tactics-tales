---@diagnostic disable: undefined-global
local M = {}

local function utf8_chars(s, fn)
  local i = 1
  while i <= #s do
    local b = s:byte(i)
    local len = (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
    fn(s:sub(i, i + len - 1))
    i = i + len
  end
end

function M.encode(glyphs, config)
  local bw = 8
  local bh = 8
  local bitmap_bytes = {}

  utf8_chars(config.p8_chars, function(ch)
    local pixels = glyphs[ch]
    if not pixels then
      io.stderr:write(string.format("Warning: no glyph for %q, substituting blank\n", ch))
      pixels = {}
      for y = 0, bh - 1 do
        pixels[y] = {}
        for x = 0, bw - 1 do pixels[y][x] = false end
      end
    end

    for y = 0, bh - 1 do
      local byte_val, bit_pos = 0, 0
      for x = 0, bw - 1 do
        if pixels[y][x] then
          byte_val = byte_val | (1 << bit_pos)
        end
        bit_pos = bit_pos + 1
        if bit_pos == 8 then
          table.insert(bitmap_bytes, byte_val)
          byte_val, bit_pos = 0, 0
        end
      end
      if bit_pos > 0 then
        table.insert(bitmap_bytes, byte_val)
      end
    end

  end)

  return bitmap_bytes
end

return M
