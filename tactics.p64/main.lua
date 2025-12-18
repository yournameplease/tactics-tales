--[[pod_format="raw",created="2025-11-14 23:50:30",modified="2025-12-18 01:26:36",revision=81,xstickers={}]]
-- tactics game
-- ynp
-- template based on abledbody's https://github.com/abledbody/picotron-external-template

local _modules = {}

function require(name)
	if _modules[name] == nil then
		local build_name = name:gsub('%.', '/') .. '.lua'
		build_name = build_name:gsub('src/', 'build/')
		_modules[name] = include(build_name)
	end
	return _modules[name]
end

DATP = ""
	--DATP = "tactics.p64/"
--if not fetch "build/main.lua" then
	cp("/desktop/projects/tactics/build/tactics", "build/tactics")
	cp("/desktop/projects/tactics/lib", "lib")
	--DATP = "tactics.p64/"
--end

pt = include "lib/picotron.lua"

include "build/tactics/main.lua"

include "lib/error_explorer.lua"
