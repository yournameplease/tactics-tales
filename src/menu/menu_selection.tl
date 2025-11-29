require("src/types")
require("src/menu/types")
require("src/joypad")
require("src/tactics/battle_unit")

global interface MenuSelection
    type: MenuType
    update: function(self, Joypad) 
end

global record MenuOption
    text: string
    next_state: MenuStep
    finish_command: GameEvent
end

global record GridMenuSelection
    is MenuSelection
    where self.type == "CURSOR_GRID"
    point: TilePoint
    x_max: integer
    y_max: integer
    path: { TilePoint }
    legal_tiles: Array2D<MenuTileHighlight>
end

function GridMenuSelection:update(joy: Joypad)
        self.point.x = mid(0, self.point.x + joy.dxp, self.x_max - 1)
        self.point.y = mid(0, self.point.y + joy.dyp, self.y_max - 1)
end

global record VerticalListMenuSelection
    is MenuSelection
    where self.type == "CURSOR_VERTICAL_LIST"
    i: integer
    options: { MenuOption }
end

function VerticalListMenuSelection:update(joy: Joypad)
    self.i = mid(1, self.i + joy.dyp, #self.options)
end

global record HorizontalListMenuSelection
    is MenuSelection
    where self.type == "CURSOR_HORIZONTAL_LIST"
    i: integer
    options: { MenuOption }
end

function HorizontalListMenuSelection:update(joy: Joypad)
    self.i = mid(1, self.i + joy.dxp, #self.options)
end