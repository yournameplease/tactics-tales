-- TODO: only needed for lazy dijkstra animation.
local LOG = require("src/debug")
require ("src/types")
require("src/tactics")
require("src/joypad")
require("src/tiles")

global enum MenuType
    "CURSOR_GRID"
    "CURSOR_VERTICAL_LIST"
    "CURSOR_HORIZONTAL_LIST"
end

global interface MenuSelection
    type: MenuType
    update: function(self, Joypad) 
end

global record GridMenuSelection
    is MenuSelection
    where self.type == "CURSOR_GRID"
    point: TilePoint
    x_max: integer
    y_max: integer
end

function GridMenuSelection:update(joy: Joypad)
        self.point.x = mid(0, self.point.x + joy.dxp, self.x_max - 1)
        self.point.y = mid(0, self.point.y + joy.dyp, self.y_max - 1)
end

global type MenuStep = string
global record FinishCommand
    kind: string
end

global record MenuOption
    text: string
    next_state: MenuStep
    finish_command: FinishCommand
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

global record MenuState

end

global record MenuContext

end

global record MenuManager
    menu_state: MenuState
    menu_ctx: MenuContext
    menu_selection: MenuSelection
    selection_history: { MenuSelection }

    tactics_engine: TacticsEngine
end

-- kind
-- selected_data_mapper -- returns (success bool, data) to store
-- select_transition
local MENU_DATA = {
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = {
                kind = "CURSOR_GRID",
                store_key = "acting_unit",
                validator = function (s: MenuSelection, t: TacticsEngine, ctx: MenuContext): boolean
                    return t:grid_selection_is_available_player(s, ctx) end,
                next_state = "SELECT_DESTINATION"
            },
            ["SELECT_DESTINATION"] = {
                kind = "CURSOR_GRID",
                store_key = "destination",
                validator = function (s: MenuSelection, t: TacticsEngine, ctx: MenuContext): boolean
                     return t:grid_selection_is_empty_or_acting_unit(s, ctx)
                end,
                next_state = "SELECT_ACTION",
                get_legal_tiles = function (t, ctx) return t:tiles_in_movement_and_attack_range(ctx) end
            },
            ["SELECT_ACTION"] = {
                kind = "CURSOR_VERTICAL_LIST",
                options_generator = function(ctx)
                    local options = {}
                    -- if target in range
                    if battle_manager.tactics_engine:any_target_in_range(ctx) then -- TODO: global state
                        add(options, {
                            text = "Attack",
                            next_state = "SELECT_TARGET"
                        })
                    end

                    add(options, {
                        text = "Wait",
                        finish_command = { kind = "MOVE_AND_WAIT" }
                    })

                    return options
                end
            },
            ["SELECT_TARGET"] = {
                kind = "CURSOR_GRID",
                store_key = "target",
                validator =  function (s: MenuSelection, t: TacticsEngine, ctx: MenuContext): boolean
                    return t:validate_tile_is_in_unit_attack_range(s, ctx) 
                end,
                finish_command = { kind = "MOVE_AND_ATTACK" },
                get_legal_tiles = function (t, ctx) return t:tiles_with_distance_from_unit_attacks(ctx) end
            },
        }
    }
}


function MenuManager:handle_menu_select()
    LOG.debug("Selecting "..self.menu_state.menu_id .. ":" .. self.menu_state.menu_step)
    local menu_data = MENU_DATA[self.menu_state.menu_id]
    local step_data = menu_data.steps[self.menu_state.menu_step]

    if step_data.validator ~= nil then
        local validation = step_data.validator(self.menu_selection, self.tactics_engine, self.menu_ctx)
        if not validation then return end
    end

    if self.menu_state.options ~= nil then
        step_data = self.menu_state.options[self.menu_selection.i]
    end

    add(self.selection_history, {
        step = self.menu_state.menu_step,
        selection = self.menu_selection
    })

    if step_data.kind == "CURSOR_GRID" then
        -- TODO: lazy impl.  keep track of cursor for the real path!
        if self.menu_state.menu_step == "SELECT_DESTINATION" then
            if self.menu_ctx.acting_unit ~= nil then
                local acting_unit = battle_state:get_unit_by_id(self.menu_ctx.acting_unit.unit_id)
                local costs = battle_manager.tile_manager:calculate_all_tile_costs(acting_unit.x, acting_unit.y, 0, 999) -- TODO: global battle_manager
                local path = battle_manager.tile_manager:get_path_to_tile(costs, self.menu_selection.x, self.menu_selection.y)
                self.menu_selection.path = path
            end
        end

        local selected_unit = battle_state:get_unit_at_coordinates(self.menu_selection.x, self.menu_selection.y)
        if selected_unit ~= nil then
            self.menu_selection.unit_id = selected_unit.id
        end
    end

    if step_data.store_key ~= nil then
        self.menu_ctx[step_data.store_key] = deepcopy(self.menu_selection)
    end

    if step_data.next_state ~= nil then
        self:populate_menu_state(step_data.next_state, self.menu_ctx)
    end

    if step_data.finish_command ~= nil then
        LOG.info("Emitting menu command ", step_data.finish_command.kind)
        BUS.emit(step_data.finish_command.kind, self.menu_ctx)
    end
end

function MenuManager:populate_menu_state(new_step, ctx)
    self.menu_state.menu_step = new_step

    local menu_data = MENU_DATA[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.menu_step]
    self.menu_state.kind = new_step_data.kind
    if new_step_data.options_generator ~= nil then
        self.menu_state.options = new_step_data.options_generator(ctx)
    else
        self.menu_state.options = nil
    end
    if new_step_data.get_legal_tiles ~= nil then
        self.menu_state.legal_tiles = new_step_data.get_legal_tiles(battle_manager.tactics_engine, ctx)
    else
        self.menu_state.legal_tiles = nil
    end
end

function MenuManager:handle_menu_back()
    if #self.selection_history == 0 then return end

    local previous_step = self.selection_history[#self.selection_history]
    -- TODO: use this to get last cursor position
    -- or, just push the entire active cursor onto a list
    self.selection_history[#self.selection_history] = nil
    populate_menu_state(previous_step.step, self.menu_ctx)
    selection = previous_step.selection
end


function MenuManager:set_menu(menu_id)
    -- TODO: make functional?
    self.menu_state = {
        kind = "CURSOR_GRID",
        handle_back = nil,
        x_max = 20, -- TODO
        y_max = 15, -- TODO
        menu_id = menu_id,
        menu_step = MENU_DATA[menu_id].initial_step
    }
    self.menu_selection = {
        x = 0,
        y = 0,
        i = 0
    }
end


function MenuManager:update(joy)
    if joy.lp then
        BUS.emit("TACTICS_END_PLAYER_TURN")
    elseif joy.bp then
        self:handle_menu_back()
    elseif joy.ap then
        self:handle_menu_select(battle_manager.battle_state) -- TODO: global state
    else
        self.menu_cursor:update(joy)
    end
end

return MenuManager
