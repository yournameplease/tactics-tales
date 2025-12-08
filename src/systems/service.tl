
local enum ServiceId
	-- persistent
	'service_manager'
	'ui_manager'
	'animation_manager'
	'task_manager'
	'event_bus'
	
	-- transient
	'battle_manager'
	'tactics_engine'
	'tile_manager'
	'turn_manager'
	'battle_state'
	'enemy_ai_engine'

end

global interface GameService
	id: ServiceId
end

global interface TransientGameService is GameService
	teardown: function(self)
end

global record ServiceManager
	is GameService
	where self.id == "service_manager"
	persistent_services: { ServiceId: GameService }	
	transient_services: { ServiceId: TransientGameService }	
end

function ServiceManager:register(service: GameService)
	local id = service.id
	assert(self.persistent_services[id] == nil)
	self.persistent_services[id] = service
end

function ServiceManager:register_transient(service: TransientGameService)
	local id = service.id
	assert(self.transient_services[id] == nil)
	self.transient_services[id] = service
end

function ServiceManager:teardown_transient(service: TransientGameService)
	local id = service.id
	assert(self.transient_services[id] ~= nil)
	service:teardown()
	self.transient_services[id] = nil
end

function ServiceManager.new(): ServiceManager
	local self: ServiceManager = {
		id = 'service_manager',
		persistent_services = {},
		transient_services = {},
	}
	setmetatable(self, { __index = ServiceManager })

	self:register(self)

	return self
end
