local id_generator = require("src/tactics/util/id_generator")
require("src/tactics/debug")

global type EventArgs = { string: any }

-- TODO: distinguish commands (menu actions)
-- from events?
global enum GameEvent
    "GAME_BEGIN_STORY"
    "GAME_EXIT_STORY"
    "GAME_SET_OPTIONS"
    
    "TACTICS_BEGIN_PLAYER_TURN"
    "TACTICS_END_PLAYER_TURN"
    "TACTICS_BEGIN_ENEMY_TURN"
    "TACTICS_END_ENEMY_TURN"
    "TACTICS_FINISH_ENEMY_ACTIONS"
    "TACTICS_FINISH_PLAYER_ACTIONS"
    "TACTICS_BEGIN_BATTLE"
    "TACTICS_UNIT_END_ACTION"
    "TACTICS_UNIT_DEATH"

    "INVENTORY_EQUIP_ITEM"
    "INVENTORY_UNEQUIP_ITEM"
    "INVENTORY_DISCARD_ITEM"
    
    "MOVE_AND_ATTACK"
    "MOVE_AND_WAIT"
    "BATTLE_END_VICTORY"
    "BATTLE_END_DEFEAT"

    "STORY_ADVANCE_TEXT"
    "STORY_CREATE_CHARACTER"
end

global record EventCallback
    id: integer
    callback: function(args: { string: any })
end

local record EventBus
    id_generator: id_generator.IdGenerator
    event_history: { GameEvent }
    listeners: { GameEvent: {EventCallback}}
end

local event_bus = {
    EventBus = EventBus
}

local MAX_EVENT_HISTORY = 20

function event_bus.new(): EventBus
    local self: EventBus = setmetatable({}, {
        __index = EventBus
    })

    self.id_generator = id_generator.new()
    self.event_history = {}
    self.listeners = {}
    return self
end

function EventBus:on(event_name: GameEvent, callback: function(args: { string: any })): integer
    if not self.listeners[event_name] then
        self.listeners[event_name] = {}
    end
    pt.add(self.listeners[event_name], {
        id = self.id_generator:get_id(),
        callback = callback
    })
end

function EventBus:remove(id: integer)
    -- lazy
    for _,slots in pairs(self.listeners) do
        for i,listener in ipairs(slots) do
            if listener.id == id then
                pt.deli(slots, i)
                return
            end
        end
    end
    error("failed to remove listener")
end

function EventBus:remove_all(ids: {integer})
    for _, id in ipairs(ids) do
        self:remove(id)
    end
end

function EventBus:emit(event_name: GameEvent, args: {string: any})
    LOG.debug("Recieved event", event_name)
    if #self.event_history > MAX_EVENT_HISTORY then
        pt.deli(self.event_history, 1)
    end
    pt.add(self.event_history, event_name)

    local slots = self.listeners[event_name]
    if slots then
        for _,listener in ipairs(slots) do
            listener.callback(args)
        end
    end
end

function EventBus:get_event_history(row_limit: integer): { GameEvent }
    local out = {}
    for i=1,row_limit do
        pt.add(out, self.event_history[i])
    end
    return out
end

return event_bus
