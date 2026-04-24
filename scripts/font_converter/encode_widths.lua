---@diagnostic disable: undefined-global
local M = {}

function M.encode(char_widths, config)
  local base = config.base_width
  local deltas = {}

  local descender_set = {}
  if config.descender_chars then
    for i = 1, #config.descender_chars do
      descender_set[config.descender_chars:sub(i, i)] = true
    end
  end

  for code = 16, 255 do
    local ch = string.char(code)
    local w = char_widths[ch] or base
    local delta = w - base
    if delta > 3 then
      io.stderr:write(string.format("Warning: char %q width delta %d clamped to +3\n", ch, delta))
      delta = 3
    elseif delta < -4 then
      io.stderr:write(string.format("Warning: char %q width delta %d clamped to -4\n", ch, delta))
      delta = -4
    end
    -- bits 2-0: 3-bit two's complement width delta; bit 3: 1 = non-descender (draws 1px higher)
    local nibble = delta >= 0 and delta or (delta + 8)
    if not descender_set[ch] then nibble = nibble | 8 end
    deltas[code] = nibble
  end

  local width_bytes = {}
  for code = 16, 256, 2 do
    local lo = deltas[code]     or 0
    local hi = deltas[code + 1] or 0
    table.insert(width_bytes, lo | (hi << 4))
  end

  return width_bytes
end

return M
