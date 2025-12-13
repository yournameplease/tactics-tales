require("src/menu/menu_cursor")
require("src/game_context")

global type MenuState
global type MenuContext

global record GridMenuDefinition<GC is GameContext>
    is MenuStepDefinition<GC>
    where self.type == "CURSOR_GRID"

    set_selected_context: function(GridMenuCursor<GC>, GC, MenuContext)
    validator: function(GridMenuCursor<GC>, GC, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
    get_legal_tiles: function(GC, MenuContext): Array2D<MenuTileHighlight>
end

global record GridMenuCursor<GC is GameContext>
    is MenuCursor<GC, GridMenuDefinition<GC>>
    where self.type == "CURSOR_GRID"
    point: TilePoint
    x_max: integer
    y_max: integer
    path: { TilePoint }
    legal_tiles: Array2D<MenuTileHighlight>

    -- from definition
    set_selected_context: function(GridMenuCursor<GC>, GC, MenuContext)
    validator: function(GridMenuCursor<GC>, GC, MenuContext): boolean
    next_state: MenuStep
    send_command: GameEvent
end

function GridMenuDefinition.new(props: GridMenuDefinition<GC>): GridMenuDefinition<GC>
    props.type = "CURSOR_GRID"
    return props
end

function GridMenuCursor.new(step_definition: GridMenuDefinition<GC>, game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): GridMenuCursor<GC>
    local self: GridMenuCursor<GC> = {
        type = "CURSOR_GRID",
        point = menu_state.point, 
        x_max = 16,
        y_max = 16
    }
    if step_definition.get_legal_tiles ~= nil then
        self.legal_tiles = step_definition.get_legal_tiles(game_ctx, menu_ctx)
    else
        self.legal_tiles = nil
    end
    return setmetatable(self, { __index = function(t: any, k: string): any 
            if (GridMenuCursor as {string: any})[k] then
                return (GridMenuCursor as {string: any})[k]
            end
            return (step_definition as {string: any})[k]
        end
        })
end

function GridMenuCursor:update(joy: Joypad)
        self.point.x = mid(0, self.point.x + joy.dxp, self.x_max - 1)
        self.point.y = mid(0, self.point.y + joy.dyp, self.y_max - 1)
end

function GridMenuCursor:handle_selection(game_ctx: GC, menu_ctx: MenuContext, menu_state: MenuState): string, GameEvent
        local validation = self.validator(self, game_ctx, menu_ctx)
        if not validation then return end

        -- if self.menu_ctx.acting_unit ~= nil and self.menu_state.step == "SELECT_DESTINATION" then
        --     -- TODO: keep path in the cursor data, and let battle menu manager do dijkstra
        --     menu_cursor.path = { TilePoint.of(0, 0)  }
        -- end

        menu_state.point = self.point:copy()
        self.set_selected_context(self, game_ctx, menu_ctx)
        return self.next_state, self.send_command
end