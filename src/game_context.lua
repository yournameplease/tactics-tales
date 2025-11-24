local GameContext = {}

function GameContext.new(
    tactics,
    turn_manager,
    tile_manager,
    character_manager,
    menu_manager
)
    local context = {
        tactics = tactics,
        turn_manager = turn_manager,
        tile_manager = tile_manager,
        character_manager = character_manager,
        menu_manager = menu_manager,

        selected_unit_id = 1
    }
    setmetatable(context, { __index = GameContext })
    return context
end

function GameContext:get_selected_unit()
    return self.tactics:get_unit_by_id(self.selected_unit_id)
end

function GameContext:enrich()

    if self.menu_manager.menu_state.kind == "CURSOR_GRID" then
        local x, y = self.menu_manager.menu_selection.x, self.menu_manager.menu_selection.y
        local unit = self.tactics:get_unit_at_coordinates(x, y)
        if unit then
            self.selected_unit_id = unit.id
        end
    end

end

return GameContext