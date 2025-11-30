require("src/debug")
require ("src/types")
require ("src/menu/types")
require ("src/menu/menu_selection")
-- TODO: tactics is only needed for lazy dijkstra animation.
require("src/tactics")
require("src/joypad")
require("src/tiles")




global record SelectionHistory
    step: MenuStep
    selection: MenuSelection
end

global record MenuManager
    menu_state: MenuState
    menu_ctx: MenuContext
    menu_selection: MenuSelection
    selection_history: { SelectionHistory }

    tactics_engine: TacticsEngine
    battle_state: BattleState
    tile_manager: TileManager
    event_bus: EventBus
end

function MenuManager.new(
    tactics_engine: TacticsEngine,
    battle_state: BattleState,
    tile_manager: TileManager,
    event_bus: EventBus
): MenuManager
    local self: MenuManager = setmetatable({}, { __index = MenuManager })

    self.menu_state = {
        point = TilePoint.of(0, 0)
    }
    self.menu_ctx = {}
    self.menu_selection = {}
    self.selection_history = {}

    self.tactics_engine = tactics_engine
    self.battle_state = battle_state
    self.tile_manager = tile_manager
    self.event_bus = event_bus

    return self
end

global interface MenuStepDefinition
    type: MenuType
end

global record GridMenuDefinition
    is MenuStepDefinition
    where self.type == "CURSOR_GRID"
    set_selected_context: function(GridMenuSelection, BattleState, MenuContext)
    validator: function(GridMenuSelection, TacticsEngine, MenuContext): boolean
    next_state: MenuStep
    finish_command: GameEvent
    get_legal_tiles: function(TacticsEngine, MenuContext): Array2D<MenuTileHighlight>
end

function GridMenuDefinition.new(props: GridMenuDefinition): GridMenuDefinition
    return props
end

global record ListMenuDefinition
    is MenuStepDefinition
    where self.type == "CURSOR_VERTICAL_LIST" -- or horizontal
    get_options: function(TacticsEngine, MenuContext): {MenuOption}
end

function ListMenuDefinition.new(props: ListMenuDefinition): ListMenuDefinition
    return props
end

global record MenuDefinition
    initial_step: MenuStep
    steps: { MenuStep: MenuStepDefinition }
end

-- kind
-- selected_data_mapper -- returns (success bool, data) to store
-- select_transition
local MENU_DATA: { MenuId: MenuDefinition } = {
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = GridMenuDefinition.new({
                type = "CURSOR_GRID",
                set_selected_context = function(s: GridMenuSelection, bs: BattleState, ctx: MenuContext)
                    ctx.acting_unit = { unit = bs:get_at_tile(s.point)}
                end,
                validator = function (s: MenuSelection, te: TacticsEngine, _ctx: MenuContext): boolean
                    return te:grid_selection_is_available_player(s) end,
                next_state = "SELECT_DESTINATION"
            }),
            ["SELECT_DESTINATION"] = GridMenuDefinition.new({
                type = "CURSOR_GRID",
                set_selected_context = function(s: GridMenuSelection, _bs: BattleState, ctx: MenuContext)
                    ctx.destination = { point = s.point:copy(), path = s.path }
                end,
                validator = function (s: MenuSelection, te: TacticsEngine, ctx: MenuContext): boolean
                     return te:grid_selection_is_empty_or_acting_unit(s, ctx)
                end,
                next_state = "SELECT_ACTION",
                get_legal_tiles = function (te: TacticsEngine, ctx: MenuContext): Array2D<MenuTileHighlight>
                    return te:tiles_in_movement_and_attack_range(ctx)
                end
            }),
            ["SELECT_ACTION"] = ListMenuDefinition.new({
                type = "CURSOR_VERTICAL_LIST",
                get_options = function(te: TacticsEngine, ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}
                    -- if target in range
                    if te:any_target_in_range(ctx) then -- TODO: global state
                        add(options, {
                            text = "Attack",
                            next_state = "SELECT_TARGET"
                        })
                    end

                    add(options, {
                        text = "Wait",
                        finish_command = "MOVE_AND_WAIT"
                    })

                    return options
                end
            }),
            ["SELECT_TARGET"] = GridMenuDefinition.new({
                type = "CURSOR_GRID",
                set_selected_context = function(s: GridMenuSelection, bs: BattleState, ctx: MenuContext)
                    ctx.target_unit = { unit = bs:get_at_tile(s.point)}
                end,
                validator =  function (s: MenuSelection, te: TacticsEngine, ctx: MenuContext): boolean
                    return te:validate_tile_is_in_unit_attack_range(s, ctx) 
                end,
                finish_command = "MOVE_AND_ATTACK",
                get_legal_tiles = function (te: TacticsEngine, ctx: MenuContext): Array2D<MenuTileHighlight>
                    return te:tiles_with_distance_from_unit_attacks(ctx)
                end
            }),
        }
    }
}


function MenuManager:populate_menu_state(new_step: MenuStep)
    self.menu_state.step = new_step

    local menu_data = MENU_DATA[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]
    if new_step_data is GridMenuDefinition then
        local new_selection = GridMenuSelection.new(
            self.menu_state.point:copy(),
            16,
            16
        )
        if new_step_data.get_legal_tiles ~= nil then
            new_selection.legal_tiles = new_step_data.get_legal_tiles(self.tactics_engine, self.menu_ctx)
        else
            new_selection.legal_tiles = nil
        end
        self.menu_selection = new_selection
    elseif new_step_data is ListMenuDefinition then
        local new_selection = VerticalListMenuSelection.new(
            0,
            new_step_data.get_options(self.tactics_engine, self.menu_ctx)
        )
        self.menu_selection = new_selection
    else
        error("not implemented")
    end
end

function MenuManager:handle_menu_select()
    LOG.debug("Selecting "..self.menu_state.menu_id .. ":" .. self.menu_state.step)
    local menu_data = MENU_DATA[self.menu_state.menu_id]
    local step_data = menu_data.steps[self.menu_state.step]

    local next_state: MenuStep
    local finish_command: GameEvent

    local menu_selection = self.menu_selection

    if step_data is GridMenuDefinition then
        assert(menu_selection is GridMenuSelection)
        local validation = step_data.validator(menu_selection, self.tactics_engine, self.menu_ctx)
        if not validation then return end

        if self.menu_ctx.acting_unit ~= nil and self.menu_state.step == "SELECT_DESTINATION" then
            local acting_unit = self.menu_ctx.acting_unit.unit
            local costs = self.tile_manager:calculate_all_tile_costs(acting_unit.tile.x, acting_unit.tile.y, 0, acting_unit.character.stats.movement) 
            local path = self.tile_manager:get_path_to_tile(costs, menu_selection.point)
            menu_selection.path = path
            LOG.debug("Path length: ", #path)
            for _, p in ipairs(path) do
                LOG.debug("Path point", p.x, p.y)
            end
        end

        self.menu_state.point = menu_selection.point:copy()
        step_data.set_selected_context(menu_selection, self.battle_state, self.menu_ctx)
        next_state = step_data.next_state
        finish_command = step_data.finish_command
    elseif step_data is ListMenuDefinition then
        assert(menu_selection is VerticalListMenuSelection)
        next_state = menu_selection.options[menu_selection.i].next_state
        finish_command = menu_selection.options[menu_selection.i].finish_command
    end

    add(self.selection_history, {
        step = self.menu_state.step,
        selection = self.menu_selection
    })

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end

    if finish_command ~= nil then
        LOG.info("Emitting menu command ", finish_command)
        self.event_bus:emit(finish_command, self.menu_ctx)
    end
end

function MenuManager:handle_menu_back()
    if #self.selection_history == 0 then return end

    local previous_step = self.selection_history[#self.selection_history]
    -- TODO: use this to get last cursor position
    -- or, just push the entire active cursor onto a list
    self.selection_history[#self.selection_history] = nil
    self:populate_menu_state(previous_step.step)
    self.menu_selection = previous_step.selection
end


function MenuManager:set_menu(menu_id: MenuId)
    self.menu_state.menu_id = menu_id
    self.selection_history = {}
    local step = MENU_DATA[menu_id].initial_step
    self:populate_menu_state(step)
end


function MenuManager:update(joy: Joypad)
    if joy.lp then
        self.event_bus:emit("TACTICS_END_PLAYER_TURN")
    elseif joy.bp then
        self:handle_menu_back()
    elseif joy.ap then
        self:handle_menu_select()
    else
        self.menu_selection:update(joy)
    end
end

return MenuManager
