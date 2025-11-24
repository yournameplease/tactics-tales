-- TODO: only needed for lazy dijkstra animation.
include "src/tiles.lua"

local MenuManager = {
    menu_state = {},
    menu_ctx = {},
    menu_selection = {},
    selection_history = {}
}


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
                validator = grid_selection_is_available_player,
                next_state = "SELECT_DESTINATION"
            },
            ["SELECT_DESTINATION"] = {
                kind = "CURSOR_GRID",
                store_key = "destination",
                validator = grid_selection_is_empty_or_acting_unit,
                next_state = "SELECT_ACTION",
                get_legal_tiles = tiles_in_movement_and_attack_range
            },
            ["SELECT_ACTION"] = {
                kind = "CURSOR_VERTICAL_LIST",
                options_generator = function(ctx)
                    local options = {}
                    -- if target in range
                    if any_target_in_range(ctx) then
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
                validator = validate_tile_is_in_unit_attack_range,
                finish_command = { kind = "MOVE_AND_ATTACK" },
                get_legal_tiles = tiles_with_distance_from_unit_attacks
            },
        }
    }
}


local update_cursor = {
    ["CURSOR_GRID"] = function (joy)
        MenuManager.menu_selection.x = mid(0, MenuManager.menu_selection.x + joy.dxp, MenuManager.menu_state.x_max - 1)
        MenuManager.menu_selection.y = mid(0, MenuManager.menu_selection.y + joy.dyp, MenuManager.menu_state.y_max - 1)
    end,
    ["CURSOR_VERTICAL_LIST"] = function (joy)
        MenuManager.menu_selection.i = mid(1, MenuManager.menu_selection.i + joy.dyp, #MenuManager.menu_state.options)
    end,
    ["CURSOR_HORIZONTAL_LIST"] = function (joy)
        MenuManager.menu_selection.i = mid(1, MenuManager.menu_selection.i + joy.dxp, #MenuManager.menu_state.options)
    end,
}

function handle_menu_select()
    printh("Select "..MenuManager.menu_state.menu_id .. ":" .. MenuManager.menu_state.menu_step)
    local menu_data = MENU_DATA[MenuManager.menu_state.menu_id]
    local step_data = menu_data.steps[MenuManager.menu_state.menu_step]

    if step_data.validator ~= nil then
        local validation = step_data.validator(MenuManager.menu_selection, MenuManager.menu_ctx)
        if not validation then return end
    end

    if MenuManager.menu_state.options ~= nil then
        step_data = MenuManager.menu_state.options[MenuManager.menu_selection.i]
    end

    add(MenuManager.selection_history, {
        step = MenuManager.menu_state.menu_step,
        selection = MenuManager.menu_selection
    })

    if step_data.kind == "CURSOR_GRID" then
        -- TODO: lazy impl.  keep track of cursor for the real path!
        if MenuManager.menu_state.menu_step == "SELECT_DESTINATION" then
            if MenuManager.menu_ctx.acting_unit ~= nil then
                local acting_unit = Battle:get_unit_by_id(MenuManager.menu_ctx.acting_unit.unit_id)
                printh(acting_unit.x.." "..acting_unit.y)
                local costs = calculate_all_tile_costs(acting_unit.x, acting_unit.y, 0, 999)
                local path = get_path_to_tile(costs, MenuManager.menu_selection.x, MenuManager.menu_selection.y)
                printh("path length "..#path)
                MenuManager.menu_selection.path = path
            end
        end

        printh("unit getting")
        local selected_unit = Battle:get_unit_at_coordinates(MenuManager.menu_selection.x, MenuManager.menu_selection.y)
        if selected_unit ~= nil then
            MenuManager.menu_selection.unit_id = selected_unit.id
        end
    end

    if step_data.store_key ~= nil then
        printh("writing to "..step_data.store_key.."...")
        printh("x="..(MenuManager.menu_selection.x or "nil"))
        printh("y="..(MenuManager.menu_selection.y or "nil"))
        printh("i="..(MenuManager.menu_selection.i or "nil"))
        printh("unit_id="..(MenuManager.menu_selection.unit_id or "nil"))
        MenuManager.menu_ctx[step_data.store_key] = deepcopy(MenuManager.menu_selection)
    end

    if step_data.next_state ~= nil then
        populate_menu_state(step_data.next_state, MenuManager.menu_ctx)
    end

    if step_data.finish_command ~= nil then
        printh("emitting "..step_data.finish_command.kind)
        BUS.emit(step_data.finish_command.kind, MenuManager.menu_ctx)
    end
end

function populate_menu_state(new_step, ctx)
    MenuManager.menu_state.menu_step = new_step

    local menu_data = MENU_DATA[MenuManager.menu_state.menu_id]
    local new_step_data = menu_data.steps[MenuManager.menu_state.menu_step]
    MenuManager.menu_state.kind = new_step_data.kind
    if new_step_data.options_generator ~= nil then
        MenuManager.menu_state.options = new_step_data.options_generator(ctx)
        printh ("generated "..#MenuManager.menu_state.options.." options")
    else
        MenuManager.menu_state.options = nil
    end
    if new_step_data.get_legal_tiles ~= nil then
        MenuManager.menu_state.legal_tiles = new_step_data.get_legal_tiles(ctx)
    else
        MenuManager.menu_state.legal_tiles = nil
    end
end

local function handle_menu_back()
    if #MenuManager.selection_history == 0 then return end

    local previous_step = MenuManager.selection_history[#MenuManager.selection_history]
    -- TODO: use this to get last cursor position
    -- or, just push the entire active cursor onto a list
    MenuManager.selection_history[#MenuManager.selection_history] = nil
    populate_menu_state(previous_step.step, MenuManager.menu_ctx)
    selection = previous_step.selection
end


function MenuManager.set_menu(menu_id)
    -- TODO: make functional?
    MenuManager.menu_state = {
        kind = "CURSOR_GRID",
        handle_back = nil,
        x_max = 20, -- TODO
        y_max = 15, -- TODO
        menu_id = menu_id,
        menu_step = MENU_DATA[menu_id].initial_step
    }
    MenuManager.menu_selection = {
        x = 0,
        y = 0,
        i = 0
    }
end


function MenuManager.update(joy)
    if joy.lp then
        BUS.emit("TACTICS_END_PLAYER_TURN")
    elseif joy.bp then
        handle_menu_back()
    elseif joy.ap then
        handle_menu_select()
    else
        update_cursor[MenuManager.menu_state.kind](joy)
    end
end

return MenuManager