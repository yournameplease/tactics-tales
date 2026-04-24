---@diagnostic disable: undefined-global
local M = {}

function M.encode(char_widths, config)
  local base = config.base_width
  local deltas = {}

  for code = 16, 127 do
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
    -- 3-bit two's complement: 0..3 = +0..+3, 4..7 = -4..-1
    deltas[code] = delta >= 0 and delta or (delta + 8)
  end

  local width_bytes = {}
  for code = 32, 126, 2 do
    local lo = deltas[code]     or 0
    local hi = deltas[code + 1] or 0
    table.insert(width_bytes, lo | (hi << 4))
  end

  return width_bytes
end

return M
