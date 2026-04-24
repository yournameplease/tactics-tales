---@diagnostic disable: undefined-global
local M = {}

function M.write(bitmap_bytes, width_bytes, config)
  local header = {
    8,
    8,
    config.x_offset,
    config.y_offset,
    0x03,  -- flags: variable-width + picotron default bit
  }

  local out = assert(io.open(config.output_font, "wb"),
    "Cannot open output: " .. config.output_font)

  out:write("--[[pod]]")
  for _, b in ipairs(header) do
    out:write(string.char(b))
  end
  for _, b in ipairs(bitmap_bytes) do
    out:write(string.char(b))
  end
  for _, b in ipairs(width_bytes) do
    out:write(string.char(b))
  end

  out:close()

  local total = #header + #bitmap_bytes + #width_bytes
  print(string.format("Done. Wrote %d bytes to %s", total, config.output_font))
end

return M
