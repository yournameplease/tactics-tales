local real_require = require

_G.require = function(path: string): any
	local trimmed_path = string.gsub(path, "^src%.", "")
	return real_require(trimmed_path)
end
