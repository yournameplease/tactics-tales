
local str <const> = {}

---@desc
--- Populate "{key}" strings with values from the map 
function str.format(template: string, values: { string: any}): string
	local out = template
	for k,v in pairs(values) do
		out = out:gsub("{"..k.."}", tostring(v))
	end
	return out
end

return str
