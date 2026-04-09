local real_require = require

---@param path string
---@return any
_G.require = function(path)
	local trimmed_path = string.gsub(path, "^src%.", "")
	return real_require(trimmed_path)
end
