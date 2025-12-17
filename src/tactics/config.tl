require("src/tactics/types")
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
	TILE_SIZE: ScalePoint
	WALL_HEIGHT: integer 
	COLOR_MENU_PRIMARY: integer 
	COLOR_MENU_SECONDARY: integer 
	COLOR_MENU_TEXT: integer 
	COLOR_MENU_HIGHLIGHT: integer 
	COLOR_MENU_HIGHLIGHT_TEXT: integer 
end

global CONFIG: Config = {

	LOG_LEVEL = "DEBUG",

	SCREEN_WIDTH = 480,
	SCREEN_HEIGHT = 270,
	MAP_WIDTH = 16,
	MAP_HEIGHT = 16,
	TILE_SIZE = ScalePoint.of(20,16),
	WALL_HEIGHT = 16,

	COLOR_MENU_PRIMARY = 32,
	COLOR_MENU_SECONDARY = 7,
	COLOR_MENU_TEXT = 7,
	COLOR_MENU_HIGHLIGHT = 6,
	COLOR_MENU_HIGHLIGHT_TEXT = 32

}

return CONFIG
