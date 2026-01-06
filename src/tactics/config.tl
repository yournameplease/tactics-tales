local point = require("src/tactics/util/point")
local Point = point.Point
-- constant configs.  eventually, may move back into relevant files.

global enum LogLevel
    "ERROR"
    "WARN"
    "INFO"
    "DEBUG"
    "TRACE"
end

global record Config
	LOG_LEVEL: LogLevel
	SCREEN_WIDTH: integer 
	SCREEN_HEIGHT: integer 
	MAP_WIDTH: integer 
	MAP_HEIGHT: integer 
	TILE_SIZE: Point
	WALL_HEIGHT: integer 
end

global CONFIG: Config = {

	LOG_LEVEL = "INFO",

	SCREEN_WIDTH = 480,
	SCREEN_HEIGHT = 270,
	MAP_WIDTH = 16,
	MAP_HEIGHT = 16,
	TILE_SIZE = point.of(20,16),
	WALL_HEIGHT = 16,

}

return CONFIG
