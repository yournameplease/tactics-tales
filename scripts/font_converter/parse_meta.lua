---@diagnostic disable: undefined-global
local M = {}

local function utf8_seq_len(b)
  if b >= 0xF0 then return 4
  elseif b >= 0xE0 then return 3
  elseif b >= 0xC0 then return 2
  else return 1
  end
end

-- Parse Construct 3 SpriteFont spacing data JSON array.
-- Returns table: char -> pixel_width (ASCII 32–127 only).
local function parse_construct3_spacing(data_str)
  local char_widths = {}
  local i = 1
  local len = #data_str
  while i <= len do
    local s, e, w_str = data_str:find("%[(%d+),\"", i)
    if not s then break end
    local w = tonumber(w_str)
    i = e + 1
    -- Read chars until unescaped closing "
    while i <= len do
      local b = data_str:byte(i)
      if b == 0x5C then -- backslash escape
        i = i + 1
        if i <= len then
          local esc = data_str:byte(i)
          if esc >= 32 and esc <= 127 then
            char_widths[string.char(esc)] = w
          end
          i = i + 1
        end
      elseif b == 0x22 then -- closing "
        i = i + 1
        break
      elseif b < 128 then -- ASCII
        if b >= 32 then
          char_widths[string.char(b)] = w
        end
        i = i + 1
      else -- multi-byte UTF-8: skip
        i = i + utf8_seq_len(b)
      end
    end
  end
  return char_widths
end

local function parse_construct3(lines)
  local char_widths = {}
  local found_header = false
  for _, line in ipairs(lines) do
    if found_header then
      local trimmed = line:match("^%s*(.-)%s*$")
      if trimmed ~= "" then
        char_widths = parse_construct3_spacing(trimmed)
        break
      end
    elseif line:match("^Spacing data:") then
      local inline = line:match("^Spacing data:%s*(%[.+)")
      if inline then
        char_widths = parse_construct3_spacing(inline)
        break
      end
      found_header = true
    end
  end
  return char_widths
end

-- Simple format: lines like "N: chars"
local function parse_simple(lines)
  local char_widths = {}
  for _, line in ipairs(lines) do
    local n, chars = line:match("^(%d+):%s*(.+)")
    if n then
      local w = tonumber(n)
      for pos = 1, #chars do
        char_widths[chars:sub(pos, pos)] = w
      end
    end
  end
  return char_widths
end

function M.parse(meta_path, config)
  local f = assert(io.open(meta_path, "r"), "Cannot open " .. meta_path)
  local content = f:read("*a")
  f:close()

  local lines = {}
  for line in content:gmatch("[^\n]+") do
    table.insert(lines, (line:gsub("\r$", "")))
  end

  local char_widths
  if lines[1] and lines[1]:match("^CONSTRUCT 3") then
    char_widths = parse_construct3(lines)
  else
    char_widths = parse_simple(lines)
  end

  -- Default missing sheet chars to base_width
  local base = config.base_width
  if config.sheet_chars then
    local i = 1
    while i <= #config.sheet_chars do
      local b = config.sheet_chars:byte(i)
      local seq = utf8_seq_len(b)
      if seq == 1 then
        local ch = config.sheet_chars:sub(i, i)
        if not char_widths[ch] then
          char_widths[ch] = base
        end
      end
      i = i + seq
    end
  end

  -- Apply manual overrides
  if config.manual_widths then
    for ch, w in pairs(config.manual_widths) do
      char_widths[ch] = w
    end
  end

  return char_widths
end

return M
