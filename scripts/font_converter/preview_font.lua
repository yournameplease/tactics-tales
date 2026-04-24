-- Usage: lua preview_font.lua <file.font>
local path = arg[1] or error("Usage: lua preview_font.lua <file.font>")

local f = assert(io.open(path, "r"))
local content = f:read("*a")
f:close()

local hex = content:match('hex:([0-9a-fA-F]+)"')
assert(hex, "no hex data found in " .. path)

local bytes = {}
for i = 1, #hex, 2 do
  bytes[#bytes + 1] = tonumber(hex:sub(i, i + 1), 16)
end

local TILE  = 8
local COLS  = 16
local total = math.floor(#bytes / TILE)

for block_start = 0, total - 1, COLS do
  for row = 0, TILE - 1 do
    local line = {}
    for col = 0, COLS - 1 do
      local idx = block_start + col
      if idx < total then
        local b = bytes[idx * TILE + row + 1] or 0
        for bit = 0, TILE - 1 do
          line[#line + 1] = ((b & (1 << bit)) ~= 0) and "█" or "░"
        end
        line[#line + 1] = " "
      end
    end
    print(table.concat(line))
  end
  print()
end
