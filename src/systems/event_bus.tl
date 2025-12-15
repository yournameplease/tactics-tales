require("src/systems/service")
require("src/util")
require("src/debug")

global enum GameEvent
    "GAME_BEGIN_STORY"
    
    "TACTICS_BEGIN_PLAYER_TURN"
    "TACTICS_END_PLAYER_TURN"
    "TACTICS_BEGIN_ENEMY_TURN"
    "TACTICS_END_ENEMY_TURN"
    "TACTICS_BEGIN_BATTLE"
    "TACTICS_UNIT_END_ACTION"

    "INVENTORY_EQUIP_ITEM"
    "INVENTORY_UNEQUIP_ITEM"
    "INVENTORY_DISCARD_ITEM"
    
    "MOVE_AND_ATTACK"
    "MOVE_AND_WAIT"
    "BATTLE_END_VICTORY"
    "BATTLE_END_DEFEAT"

    "STORY_ADVANCE_TEXT"
end

global record EventListener
    id: integer
    callback: function(args: any)
end

global record EventBus
    is GameService
    where self.id == "event_bus"
    id_counter: IdCounter
    event_history: { GameEvent }
    listeners: { GameEvent: {EventListener}}
end

function EventBus:init(_service_manager: ServiceManager, _services: { ServiceId: GameService })

end

local MAX_EVENT_HISTORY = 99

function EventBus.new(): EventBus
    local self: EventBus = setmetatable({
        id = "event_bus",
        dependencies = {},
    }, { __index = EventBus })

    self.id_counter = IdCounter.new()
    self.event_history = {}
    self.listeners = {}
    return self
end

function EventBus:on(event_name: GameEvent, callback: function(args: any)): integer
    if not self.listeners[event_name] then
        self.listeners[event_name] = {}
    end
    pt.add(self.listeners[event_name], {
        id = self.id_counter:get_id(),
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

function EventBus:emit(event_name: GameEvent, args?: any)
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

function EventBus:get_event_history(): { GameEvent }
    return self.event_history
end

return EventBus
