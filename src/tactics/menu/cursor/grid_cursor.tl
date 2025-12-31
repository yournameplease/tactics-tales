local point = require("src/tactics/util/point")
local Point = point.Point
local menu_cursor = require("src/tactics/menu/menu_cursor")
require("src/tactics/menu/types")
local Joypad = require("src/tactics/joypad").Joypad
local array_2d = require("src/tactics/util/array_2d")
local pathfinding = require("src/tactics/battle/pathfinding")
local event_bus = require("src/tactics/systems/event_bus")

local record MenuTileHighlight
    reachable: boolean
    valid_selection: boolean
    can_attack: boolean
end

local record GridMenuCursor<GC>
    is menu_cursor.MenuCursor<GC>
    where self.type == "CURSOR_GRID"
    point: Point
    x_max: integer
    y_max: integer
    path: { Point }
    legal_tiles: array_2d.Array2D<MenuTileHighlight>
    max_path_length: integer

    -- from definition
    set_selected_context: function(GridMenuCursor<GC>, GC, MenuContext)
    validator: function(GridMenuCursor<GC>, GC, MenuContext): boolean
    next_state: MenuStep
    send_command: event_bus.GameEvent
end

local record GridMenuDefinition<GC>
    is menu_cursor.MenuStepDefinition<GC>
    where self.type == "CURSOR_GRID"

    set_selected_context: function(GridMenuCursor<GC>, GC, MenuContext)
    validator: function(GridMenuCursor<GC>, GC, MenuContext): boolean
    next_state: MenuStep
    send_command: event_bus.GameEvent
    get_legal_tiles: function(GC, MenuContext): array_2d.Array2D<MenuTileHighlight>
    get_path_anchor: function(GC, MenuContext): Point
    get_max_path_length: function(GC, MenuContext): integer
end

local grid_cursor = {
    MenuTileHighlight = MenuTileHighlight,
    GridMenuCursor = GridMenuCursor,
    GridMenuDefinition = GridMenuDefinition,
}

function grid_cursor.definition<GC>(
    props: GridMenuDefinition<GC>
): GridMenuDefinition<GC>
    props.type = "CURSOR_GRID"
    return setmetatable(props, { __index = GridMenuDefinition })
end

function GridMenuCursor:update(
    joy: Joypad
)
    local prev_point = self.point:copy()
    self.point.x = pt.mid(0, self.point.x + joy.dxp, self.x_max - 1)
    self.point.y = pt.mid(0, self.point.y + joy.dyp, self.y_max - 1)

    if self.legal_tiles ~= nil and self.path ~= nil and self.point ~= prev_point then
        LOG.debug(prev_point, self.point, #self.path)
        if self.legal_tiles:get_point(self.point) then
            
            local tiles = self.legal_tiles:map(function(h: MenuTileHighlight): boolean
                return h ~= nil and h.reachable
            end)
            self.path = pathfinding.extend_path_to_point(self.path, self.point, self.max_path_length, tiles)
            LOG.debug(#self.path, self.path[1],self.path[#self.path])
        end
    end 
end

function GridMenuCursor:handle_select(
    game_ctx: GC,
    menu_ctx: MenuContext,
    menu_state: MenuState
): string, event_bus.GameEvent
    local validation = self.validator(self, game_ctx, menu_ctx)
    if not validation then return end

    menu_state.point = self.point:copy()
    self.set_selected_context(self, game_ctx, menu_ctx)
    return self.next_state, self.send_command
end

function GridMenuDefinition:to_cursor(
    game_ctx: GC,
    menu_ctx: MenuContext,
    menu_state: MenuState
): menu_cursor.MenuCursor<GC>
    local cursor: GridMenuCursor<GC> = {
        type = "CURSOR_GRID",
        point = menu_state.point, 
        x_max = 16,
        y_max = 16
    }
    if self.get_legal_tiles ~= nil then
        cursor.legal_tiles = self.get_legal_tiles(game_ctx, menu_ctx)
        if self.get_max_path_length ~= nil then
            cursor.max_path_length = self.get_max_path_length(game_ctx, menu_ctx)
            LOG.debug("path_length", cursor.max_path_length)
            if self.get_path_anchor then
                cursor.path = {self.get_path_anchor(game_ctx, menu_ctx)}
            else
                cursor.path = {menu_state.point:copy()}
            end
        else
            cursor.path = nil
            cursor.max_path_length = nil
        end
    else
        cursor.legal_tiles = nil
    end
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (GridMenuCursor as {string: any})[k] then
                return (GridMenuCursor as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

return grid_cursor
