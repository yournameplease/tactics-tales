--- @meta

--- Gets a binary string encoding the value
--- Flags determine the encoding
---     0x0 - default
---     0x1 - pxu - RLE style compression
---     0x2 - lz4 compression
---     0x3 - base64
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#pod)
--- @param val table | string | userdata | boolean | number
--- @param flags? integer
--- @param metadata? table
--- @return string | nil
function pod(val, flags, metadata) end

--- Gets the decoded value and metadata from a POD string
--- [View Online](https://www.lexaloffle.com/dl/docs/picotron_manual.html#unpod)
--- @param val string
--- @return table | string | userdata | boolean | number | nil content
--- @return table metadata
function unpod(val) end
