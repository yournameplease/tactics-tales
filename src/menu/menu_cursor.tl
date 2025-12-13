require ("src/menu/types")
require("src/joypad")

global interface MenuCursor
    type: MenuType
    update: function(self, Joypad) 
end

global interface MenuStepDefinition
    type: MenuType
    previous_state: MenuStep
end