local GameContext = {}

function GameContext.new(
    tactics,
    turn_manager,
    tile_manager,
    character_manager,
    menu_manager,
    event_bus,
    combat_calculator
)
    local context = {
        tactics = tactics,
        turn_manager = turn_manager,
        tile_manager = tile_manager,
        character_manager = character_manager,
        menu_manager = menu_manager,
        event_bus = event_bus,
        combat_calculator = combat_calculator,

        layout = "TACTICS",

        selected_unit_id = 1,
        acting_unit_id = 1,
    }
    setmetatable(context, { __index = GameContext })
    return context
end

function GameContext:get_selected_unit()
    return self.tactics:get_unit_by_id(self.selected_unit_id)
end

function GameContext:get_acting_unit()
    return self.tactics:get_unit_by_id(self.acting_unit_id)
end

function GameContext:enrich()
    self.layout = "TACTICS"

    if self.menu_manager.menu_state.menu_step == "SELECT_UNIT" then
        local x, y = self.menu_manager.menu_selection.x, self.menu_manager.menu_selection.y
        local unit = self.tactics:get_unit_at_coordinates(x, y)
        if unit then
            self.selected_unit_id = unit.id
        end
    end

    if self.menu_manager.menu_ctx.acting_unit ~= nil then
        self.acting_unit_id = self.menu_manager.menu_ctx.acting_unit.unit_id
    end

    if self.menu_manager.menu_state.menu_step == "SELECT_TARGET" then
        local x, y = self.menu_manager.menu_selection.x, self.menu_manager.menu_selection.y
        local unit = self.tactics:get_unit_at_coordinates(x, y)
        if unit then
            self.layout = "COMBAT_PREVIEW"
            self.selected_unit_id = unit.id
        end
    end

end

return GameContext