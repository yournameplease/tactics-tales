
global enum ServiceId
	-- persistent
	'service_manager'
	'ui_manager'
	'animation_manager'
	'task_manager'
	'event_bus'
	
	'ui_context_manager'

end


-- possible todo: don't require all be manually init'd in the correct dependency order
global interface GameService
	id: ServiceId
	dependencies: { ServiceId }
	-- handles getting other services
	init: function(self, service_manager: ServiceManager, services: { ServiceId: GameService })
end

global record ServiceManager
	is GameService
	where self.id == "service_manager"
	persistent_services: { ServiceId: GameService }	
end

function ServiceManager:get_services(): { ServiceId: GameService}
	local out: { ServiceId: GameService } = {}
	for k,v in pairs(self.persistent_services) do
		out[k] = v
	end
	return out
end

function ServiceManager:assert_dependencies_exist(ids: { ServiceId }): boolean
	for _,id in ipairs(ids) do
		if self.persistent_services[id] == nil then
			error("Service '"..id.."' was expected but has not yet been initialized!" )
		end
	end
	return true
end

function ServiceManager:register<S is GameService>(service: S): S
	local id = service.id
	assert(self.persistent_services[id] == nil)
	self:assert_dependencies_exist(service.dependencies)
	self.persistent_services[id] = service
	service:init(self, self:get_services())
	return service
end

function ServiceManager:init(_service_manager: ServiceManager, _services: { ServiceId: GameService })
end

function ServiceManager.new(): ServiceManager
	local self: ServiceManager = {
		id = 'service_manager',
		dependencies = {},
	}
	setmetatable(self, { __index = ServiceManager })

	self.persistent_services = {}
	
	self:init(self, {})
	self:register(self)
	return self
end


return {
	ServiceManager = ServiceManager
}
