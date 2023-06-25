---@type table<string, fun(Self:IC2Component)>
local INIT = {
}

---@type table<string, fun(self:IC2Component):number?>
local ON = {
	["fuel-rod"] = function(self)
		local reactor = self.reactor
		if reactor.has_redstone_signal then
			self:add_heat(1)
			local around_component = self:get_current_adjacent()
			self:get_next_transfer()
			if around_component then
				around_component:add_heat(self.heat_production)
			else
				reactor:add_heat(self.heat_production)
			end
			return self.energy_prod
		end
	end,

	exchanger = function(self)
		local reactor = self.reactor
		local stats = self.const
		local around_component = self:get_current_adjacent()
		self:get_next_transfer()
		if around_component then
			local heat_comp = self.health
			local heat_around = around_component.health
			if heat_comp < heat_around then
				around_component:transfer_to(self, stats.heat_transfer)
			elseif heat_comp > heat_around then
				self:transfer_to(around_component, stats.heat_transfer)
			end
		end

		local component_health = self.health
		local reactor_health = reactor.health
		if component_health > reactor_health then
			reactor:transfer_to(self, stats.heat_pull)
		elseif component_health < reactor_health then
			self:transfer_to(reactor, stats.heat_pull)
		end
	end,

	vent = function(self)
		local stats = self.const
		self:add_heat(-stats.heat_dissipated)
	end,

	["cooling-cell"] = function(self)
	end,

	["plating"] = function(self)

	end
}
ON["reactor-heat-vent"] = function(self)
	local reactor = self.reactor
	local stats = self.const
		reactor:transfer_to(self, stats.heat_pull)
		self:add_heat(-stats.heat_dissipated)
end

ON["overclocked-heat-vent"] = function(self)
	local reactor = self.reactor
	local stats = self.const
	self:add_heat(-stats.heat_dissipated)
	reactor:transfer_to(self, stats.heat_pull)
end

ON["component-heat-vent"] = function(self)
	local stats = self.const
	for _, around_component in pairs(self.around) do
		around_component:add_heat(-stats.heat_dissipated)
	end
end

ON["reactor-heat-exchanger"] = function(self)
	local reactor = self.reactor
	local stats = self.const
	local component_health = self.health
	local reactor_health = reactor.health

	if component_health > reactor_health then
		reactor:transfer_to(self, stats.heat_pull)
	else
		self:transfer_to(reactor, stats.heat_pull)
	end
end

ON["component-heat-exchanger"] = function(self)
	local stats = self.const
	local around_component = self:get_current_adjacent()

	if around_component then
		local component_health = self.health
		local reactor_health = around_component.health
		if component_health > reactor_health then
			around_component:transfer_to(self, stats.heat_transfer)
		elseif component_health < reactor_health then
			self:transfer_to(around_component, stats.heat_transfer)
		end
	end
	self:get_next_transfer()
end

---@param self IC2Component
local function init(self)
	if INIT[self.type] then
		INIT[self.type](self)
	end
end

---@class IC2Component
---@field type ComponentType
---@field name string
---@field reactor IC2Reactor
---@field const ComponentVent|ComponentExchanger|ComponentFuel_rod|ComponentCooling_cell|ComponentPlating
---@field next_transfer number
---@field x integer
---@field y integer
---@field around IC2Component[]
---@field heat_production number
---@field heat number
---@field max_heat number
---@field health number
---@field energy_prod number
---@field adjacent_rod number
---@field on_type string
local IC2Component = {}
IC2Component.__index = IC2Component

function IC2Component.restore()
	for instance in pairs(global.class_instances.IC2Component) do
		setmetatable(instance, IC2Component)
	end
end

---@param item LuaItemStack
function IC2Component.new(reactor, item, x, y)
	local component = setmetatable({
		type = ComponentType(item.name),
		name = item.name,
		reactor = reactor,
		energy_prod = 0,
		x = x,
		y = y,
		adjacent_rod = 0
	}, IC2Component)
	component.const = COMPONENT_CONST[component.type][component.name]
	component.max_heat = component.const.maxhealth
	component.heat = math.floor((1 - item.health) * component.max_heat)
	component:calc_health()
	init(component)
	if ON[component.name] then
		component.on_type = component.name
	else
		component.on_type = component.type
	end
	global.class_instances.IC2Component[component] = true
	return component
end

function IC2Component:on()
	return ON[self.on_type](self)
end

function IC2Component:get_pos()
	return self.x, self.y
end

---@param around IC2Component[]
function IC2Component:set_around(around)
	self.around = around
end

function IC2Component:get_next_transfer()
	---@type number
	self.next_transfer = next(self.around, self.next_transfer) or next(self.around)
	return self.next_transfer
end

function IC2Component:get_current_adjacent()
	return self.around[self.next_transfer]
end

---@param heat number
function IC2Component:set_heat(heat)
	self.heat = math.max(heat, 0)
	self:calc_health()
	return self.heat
end

---@param heat number
function IC2Component:add_heat(heat)
	local old_heat = self.heat
	self.heat = math.max(self.heat + heat, 0)
	self:calc_health()
	return self.heat - old_heat
end

---@param truc IC2Component|IC2Reactor
---@param heat number
function IC2Component:transfer_to(truc, heat)
	local pull_heat = self:add_heat(-heat)
	truc:add_heat(math.abs(pull_heat))
end

function IC2Component:calc_health()
	self.health = math.max((self.max_heat - self.heat) / self.max_heat, 0)
end

function IC2Component:is_overheat()
	return self.heat >= self.max_heat
end


return IC2Component
