---@diagnostic disable: undefined-global
local M = {}

function M.write(bitmap_bytes, width_bytes, config)
  local header = {
    8,--width < 128
    8,--width >=128
    8,--height
    0,--config.x_offset,
    0,--config.y_offset,
    0x03,  -- flags: variable-width + picotron default bit
    2,  -- tab width
    #width_bytes  -- glyph count
  }

  local all_bytes = {}
  for _, b in ipairs(header) do table.insert(all_bytes, b) end
  for _, b in ipairs(width_bytes) do table.insert(all_bytes, b) end
  for _, b in ipairs(bitmap_bytes) do table.insert(all_bytes, b) end

  local hex_parts = {}
  for _, b in ipairs(all_bytes) do
    hex_parts[#hex_parts + 1] = string.format("%02x", b)
  end
  local hex = table.concat(hex_parts)

  local out = assert(io.open(config.output_font, "w"),
    "Cannot open output: " .. config.output_font)
  out:write('--[[pod]]userdata("u8",2048,"hex:' .. hex .. '")')
  out:close()

  print(string.format("Done. Wrote %d bytes to %s", #all_bytes, config.output_font))
end

return M
