--[[pod_format="raw",created="2025-11-14 23:50:30",modified="2026-04-12 18:28:57",revision=111,xstickers={}]]
-- tactics game
-- ynp
-- template based on abledbody's https://github.com/abledbody/picotron-external-template

local _modules = {}

function require(name)
	if split(name,'.')[1] ~= 'src' then
		return
	elseif _modules[name] == nil then
		local src_name = name:gsub('%.', '/') .. '.lua'
		_modules[name] = include(src_name)
	end
	return _modules[name]
end

DATP = ""
cp("/desktop/projects/tactics/src/tactics", "src/tactics")
cp("/desktop/projects/tactics/lib", "lib")
cp("/desktop/projects/tactics/mods", "mods")

include "lib/profiler.lua"

include "src/tactics/main.lua"

include "lib/error_explorer.lua"

mkdir("/appdata/tactics_tales")
