local point = require("src/tactics/util/point")
require("src/tactics/debug")
local menu_types = require ("src/tactics/menu/types")
local MenuContext = require ("src/tactics/menu/menu_context").MenuContext
local Joypad = require("src/tactics/joypad").Joypad
local event_bus = require("src/tactics/systems/event_bus")
local event_writer = require("src/tactics/systems/event_bus/event_writer")
local menu_cursor = require("src/tactics/menu/menu_cursor")

local record SelectionHistory<GC>
    step: menu_types.MenuStep
    selection: menu_cursor.MenuCursor<GC>
end

local record MenuDefinition<GC>
    initial_step: menu_types.MenuStep
    steps: { menu_types.MenuStep: menu_cursor.MenuStepDefinition<GC> }
end

local interface MenuManager<GC>
    
    menu_definitions: { menu_types.MenuId: MenuDefinition }

    menu_state: menu_types.MenuState
    menu_ctx: MenuContext
    menu_cursor: menu_cursor.MenuCursor<GC>
    selection_history: { SelectionHistory<GC> }

    game_ctx: GC
    event_writer: event_writer.EventWriter

    populate_menu_state: function(self, new_step: menu_types.MenuStep)
    handle_menu_select: function(self)
    handle_menu_back: function(self)
    set_menu: function(self, menu_id: menu_types.MenuId)
    update: function(self, joy: Joypad)
end

local record BaseMenuManager<GC>
    is MenuManager<GC>

    menu_definitions: { menu_types.MenuId: MenuDefinition<GC> }
end

local menu_manager = {
    MenuManager = MenuManager,
    SelectionHistory = SelectionHistory,
    MenuDefinition = MenuDefinition,
}

function menu_manager.new<GC>(
    menu_definitions: { menu_types.MenuId: MenuDefinition },
    ctx: GC,
    bus: event_bus.EventBus
): MenuManager<GC>
    local self: BaseMenuManager<GC> = setmetatable({}, { __index = BaseMenuManager })

    self.menu_definitions = menu_definitions

    self.menu_state = {
        point = point.of(0, 0)
    }
    self.menu_ctx = {
        metadata = {}
    }
    self.menu_cursor = {}
    self.selection_history = {}

    self.game_ctx = ctx
    self.event_writer = event_writer.new(bus)

    return self
end

function BaseMenuManager:populate_menu_state(new_step: menu_types.MenuStep)
    self.menu_state.step = new_step

    local menu_data = self.menu_definitions[self.menu_state.menu_id]
    local new_step_data = menu_data.steps[self.menu_state.step]
    
    self.menu_cursor = new_step_data:to_cursor(self.game_ctx, self.menu_ctx, self.menu_state)
end

function BaseMenuManager:handle_menu_select()
    LOG.debug("Selecting "..self.menu_state.menu_id .. ":" .. self.menu_state.step)

    local next_state, send_command = self.menu_cursor:handle_select(self.game_ctx, self.menu_ctx, self.menu_state)
    
    pt.add(self.selection_history, {
        step = self.menu_state.step,
        selection = self.menu_cursor
    })

    if send_command ~= nil then
        LOG.info("Emitting menu command ", send_command)
        self.event_writer:emit(send_command, self.menu_ctx)
    end

    if next_state ~= nil then
        self:populate_menu_state(next_state)
    end
end

function BaseMenuManager:handle_menu_back()
    local previous_step = self.menu_definitions[self.menu_state.menu_id].steps[self.menu_state.step]
        .previous_state

    if previous_step == nil then
        return
    end
    while #self.selection_history > 1 and
        self.selection_history[#self.selection_history].step ~= previous_step do
        self.selection_history[#self.selection_history] = nil
    end
    self:populate_menu_state(previous_step)
    self.menu_cursor = self.selection_history[#self.selection_history].selection
end


function BaseMenuManager:set_menu(menu_id: menu_types.MenuId)
    self.menu_state.menu_id = menu_id
    self.selection_history = {}
    local step = self.menu_definitions[menu_id].initial_step
    self:populate_menu_state(step)
end


function BaseMenuManager:update(joy: Joypad)
    if joy.lp then
        -- DEBUG Only for now.  consider where to put
        self.event_writer:emit("TACTICS_FINISH_PLAYER_ACTIONS", {})
    elseif joy.bp then
        self:handle_menu_back()
    elseif joy.ap then
        self:handle_menu_select()
    else
        self.menu_cursor:update(joy)
    end
end

return menu_manager
