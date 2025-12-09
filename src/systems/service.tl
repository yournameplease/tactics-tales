
global enum ServiceId
	-- persistent
	'service_manager'
	'ui_manager'
	'animation_manager'
	'task_manager'
	'event_bus'
	'character_manager'
	
	-- transient
	'story_manager'
	'battle_manager'
	'tactics_engine'
	'tile_manager'
	'turn_manager'
	'battle_state'
	'enemy_ai_engine'
	'menu_manager'
	'combat_calculator'
	'game_context'
	'battle_objective_service'

end


-- possible todo: don't require all be manually init'd in the correct dependency order
global interface GameService
	id: ServiceId
	dependencies: { ServiceId }
	-- handles getting other services
	init: function(self, service_manager: ServiceManager, services: { ServiceId: GameService })
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

function ServiceManager:get_services(): { ServiceId: GameService}
	local out: { ServiceId: GameService } = {}
	for k,v in pairs(self.transient_services) do
		out[k] = v
	end
	for k,v in pairs(self.persistent_services) do
		out[k] = v
	end
	return out
end

function ServiceManager:dependencies_exist(ids: { ServiceId }): boolean
	for _,id in ipairs(ids) do
		if self.persistent_services[id] == nil
			and self.transient_services[id] == nil then
			return false
		end
	end
	return true
end

function ServiceManager:register<S is GameService>(service: S): S
	local id = service.id
	assert(self.persistent_services[id] == nil)
	assert(self.transient_services[id] == nil)
	assert(self:dependencies_exist(service.dependencies))
	self.persistent_services[id] = service
	service:init(self, self:get_services())
	return service
end

function ServiceManager:register_transient<S is TransientGameService>(service: S): S
	local id = service.id
	assert(self.persistent_services[id] == nil)
	assert(self.transient_services[id] == nil)
	assert(self:dependencies_exist(service.dependencies))
	self.transient_services[id] = service
	service:init(self, self:get_services())
	return service
end

function ServiceManager:teardown_transient(service: TransientGameService)
	local id = service.id
	assert(self.transient_services[id] ~= nil)
	service:teardown()
	self.transient_services[id] = nil
end

function ServiceManager:init(service_manager: ServiceManager, services: { ServiceId: GameService })
	self.persistent_services = {}
	self.transient_services = {}
end

function ServiceManager.new(): ServiceManager
	local self: ServiceManager = {
		id = 'service_manager',
		dependencies = {},
	}
	setmetatable(self, { __index = ServiceManager })

	return self
end


return {
	ServiceManager = ServiceManager
}
