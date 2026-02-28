---@brief
--- A simple event bus for decoupled communication between systems.
--- Allows services to subscribe to and emit global game events.

local id_generator = require("src.tactics.util.id_generator")

local type EventArgs = { string: any }

-- TODO: distinguish commands (menu actions)
-- from events?
local enum GameEvent
    -- usually events    
    "TACTICS_BEGIN_TURN"
    "TACTICS_END_TURN"
    "TACTICS_BEGIN_PHASE"
    "TACTICS_END_PHASE"
    "TACTICS_FINISH_SIDE_ACTIONS"
    "TACTICS_BEGIN_BATTLE"
    "TACTICS_UNIT_END_ACTION"
    "TACTICS_UNIT_DEATH"
    "TACTICS_INTERACTION"

    "BATTLE_END_VICTORY"
    "BATTLE_END_DEFEAT"

    "GAME_EXIT_STORY"
end

local record EventCallback
    id: integer
    callback: function(args: { string: any })
end

local record EventBus
    id_generator: id_generator.IdGenerator
    event_history: { GameEvent }
    listeners: { GameEvent: {EventCallback}}
end

local event_bus = {
    EventArgs = EventArgs,
    GameEvent = GameEvent,
    EventCallback = EventCallback,
    EventBus = EventBus,
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
    local id = self.id_generator:get_id()
    pt.add(self.listeners[event_name], {
        id = id,
        callback = callback
    })
    return id
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

function EventBus:remove_all(ids: {integer: boolean})
    for id, _ in pairs(ids) do
        self:remove(id)
    end
end

function EventBus:emit(event_name: GameEvent, args: {string: any})
    log.debug("Received event", event_name)
    if args ~= nil then
        for k,v in pairs(args) do
            log.debug("arg: "..k..tostring(v))
        end
    end
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
