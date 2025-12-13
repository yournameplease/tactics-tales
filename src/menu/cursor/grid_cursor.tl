require("src/menu/menu_cursor")
require("src/game_context")

global record GridMenuCursor
    is MenuCursor
    where self.type == "CURSOR_GRID"
    point: TilePoint
    x_max: integer
    y_max: integer
    path: { TilePoint }
    legal_tiles: Array2D<MenuTileHighlight>
end

function GridMenuCursor.new(point: TilePoint, x_max: integer, y_max: integer): GridMenuCursor
    local self: GridMenuCursor = {
        type = "CURSOR_GRID",
        point = point, 
        x_max = x_max,
        y_max = y_max
    }
    return setmetatable(self, { __index = GridMenuCursor })
end

function GridMenuCursor:update(joy: Joypad)
        self.point.x = mid(0, self.point.x + joy.dxp, self.x_max - 1)
        self.point.y = mid(0, self.point.y + joy.dyp, self.y_max - 1)
end

global record GridMenuDefinition<MSB is GameContext>
    is MenuStepDefinition
    where self.type == "CURSOR_GRID"

    set_selected_context: function(GridMenuCursor, MSB, MenuContext)
    validator: function(GridMenuCursor, MSB, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
    get_legal_tiles: function(MSB, MenuContext): Array2D<MenuTileHighlight>
end

function GridMenuDefinition.new(props: GridMenuDefinition<MSB>): GridMenuDefinition<MSB>
    props.type = "CURSOR_GRID"
    return props
end