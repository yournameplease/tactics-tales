require("src/tactics/menu/menu_cursor")
require("src/tactics/menu/types")
local Joypad = require("src/tactics/joypad").Joypad
local array_2d = require("src/tactics/util/array_2d")
local pathfinding = require("src/tactics/battle/pathfinding")

global record GridMenuCursor<GC>
    is MenuCursor<GC>
    where self.type == "CURSOR_GRID"
    point: point.Point
    x_max: integer
    y_max: integer
    path: { point.Point }
    legal_tiles: array_2d.Array2D<MenuTileHighlight>
    max_path_length: integer

    -- from definition
    set_selected_context: function(GridMenuCursor<GC>, GC, MenuContext)
    validator: function(GridMenuCursor<GC>, GC, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
end

global record GridMenuDefinition<GC>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_GRID"

    set_selected_context: function(GridMenuCursor<GC>, GC, MenuContext)
    validator: function(GridMenuCursor<GC>, GC, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
    get_legal_tiles: function(GC, MenuContext): array_2d.Array2D<MenuTileHighlight>
    get_path_anchor: function(GC, MenuContext): point.Point
    get_max_path_length: function(GC, MenuContext): integer
end

function GridMenuDefinition.new(props: GridMenuDefinition<GC>): GridMenuDefinition<GC>
    props.type = "CURSOR_GRID"
    return setmetatable(props, { __index = GridMenuDefinition })
end

function GridMenuCursor.new(step_definition: any, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): GridMenuCursor<GC>
    assert(step_definition is GridMenuDefinition<GC>)
    local self: GridMenuCursor<GC> = {
        type = "CURSOR_GRID",
        point = menu_state.point, 
        x_max = 16,
        y_max = 16
    }
    if step_definition.get_legal_tiles ~= nil then
        self.legal_tiles = step_definition.get_legal_tiles(game_ctx, menu_ctx)
        if step_definition.get_max_path_length ~= nil then
            self.max_path_length = step_definition.get_max_path_length(game_ctx, menu_ctx)
            LOG.debug("path_length", self.max_path_length)
            if step_definition.get_path_anchor then
                self.path = {step_definition.get_path_anchor(game_ctx, menu_ctx)}
            else
                self.path = {menu_state.point:copy()}
            end
        else
            self.path = nil
            self.max_path_length = nil
        end
    else
        self.legal_tiles = nil
    end
    return setmetatable(self, { __index = function(_: any, k: string): any 
            if (GridMenuCursor as {string: any})[k] then
                return (GridMenuCursor as {string: any})[k]
            end
            return (step_definition as {string: any})[k]
        end
        })
end

function GridMenuCursor:update(joy: Joypad)
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

function GridMenuCursor:handle_select(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
    local validation = self.validator(self, game_ctx, menu_ctx)
    if not validation then return end

    menu_state.point = self.point:copy()
    self.set_selected_context(self, game_ctx, menu_ctx)
    return self.next_state, self.send_command
end

function GridMenuDefinition:to_cursor(game_context: GC, menu_ctx: MenuContext, menu_state: MenuState): MenuCursor<GC>
    return GridMenuCursor.new(self, game_context, menu_ctx, menu_state)
end
