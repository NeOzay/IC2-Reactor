---@type table<string, fun(Self:IC2Component)>
local INIT = {
	["fuel-rod"] = function(self)
		self.adjacent_rod = 0
	end
}

---@type table<string, fun(self:IC2Component, reactor:IC2Reactor)>
local ON = {
	["fuel-rod"] = function(self, core, reactor)
		if self:is_overheat() then
			core.layout:remove_component({ equipment = self.equipment })
			return
		end
		if reactor.has_redstone_signal then
			local around_component = self:get_current_adjacent()
			self:add_heat(1)
			if around_component and around_component:is_valid() then
				self:next_to_transfer()
				around_component:add_heat(self.heat_production)
			else
				core.core_heat = core.core_heat + self.heat_production
			end
		end
	end,

	exchanger = function(self, core)
		if self:is_overheat() then
			core.layout:remove_component({ equipment = self.equipment })
			return
		end
		local stats = self.const
		local around_component = self:get_current_adjacent()

		if around_component and around_component:is_valid() then
			local heat_comp = self:get_heat_percent()
			local heat_around = around_component:get_heat_percent()
			if heat_comp < heat_around then
				around_component:transfer_to(self, stats.heat_transfer)
			elseif heat_comp > heat_around then
				self:transfer_to(around_component, stats.heat_transfer)
			end
			self:next_to_transfer()
		end

		local heat_comp = self:get_heat_percent()
		local heat_core = core:get_heat()
		if heat_comp < heat_core then
			core:transfer_to(self, stats.heat_pull)
		elseif heat_comp > heat_core then
			self:transfer_to(core, stats.heat_pull)
		end
	end,

	vent = function(self, core)
		if self:is_overheat() then
			core.layout:remove_component({ equipment = self.equipment })
			return
		end
		local stats = self.const
		self:remove_heat(stats.heat_dissipated)
	end,

	["cooling-cell"] = function(self, core)
		if self:is_overheat() then
			core.layout:remove_component({ equipment = self.equipment })
			return
		end
	end,

	["plating"] = function(self, core)

	end
}
ON["reactor-heat-vent"] = function(self, core)
	if self:is_overheat() then
		core.layout:remove_component({ equipment = self.equipment })
		return
	end
	local stats = self.const
	local core_heat = core:get_heat()
	if core_heat >= stats.heat_pull then
		core:transfer_to(self, stats.heat_pull)
		self:remove_heat(stats.heat_dissipated)
	end
end

ON["overclocked-heat-vent"] = function(self, core)
	if self:is_overheat() then
		core.layout:remove_component({ equipment = self.equipment })
		return
	end
	local stats = self.const
	local core_heat = core:get_heat()
	self:remove_heat(stats.heat_dissipated)
	if core_heat >= stats.heat_pull then
		core:transfer_to(self, stats.heat_pull)
	end
end

ON["component-heat-vent"] = function(self, core)
	local stats = self.const
	for index, around_component in pairs(self.around) do
		around_component:remove_heat(stats.heat_dissipated)
	end
end

ON["reactor-heat-exchanger"] = function(self, core)
	if self:is_overheat() then
		core.layout:remove_component({ equipment = self.equipment })
		return
	end
	local stats = self.const
	local heat_comp = self:get_heat_percent()
	local heat_core = core:get_heat()
	if heat_comp < heat_core then
		core:transfer_to(self, stats.heat_pull)
	elseif heat_comp > heat_core then
		self:transfer_to(core, stats.heat_pull)
	end
end

ON["component-heat-exchanger"] = function(Self, core)
	if Self:is_overheat() then
		core.layout:remove_component({ equipment = Self.equipment })
		return
	end
	local stats = Self.const
	local around_component = Self:get_current_adjacent()

	if around_component and around_component:is_valid() then
		local heat_comp = Self:get_heat_percent()
		local heat_around = around_component:get_heat_percent()
		if heat_comp < heat_around then
			around_component:transfer_to(Self, stats.heat_transfer)
		elseif heat_comp > heat_around then
			Self:transfer_to(around_component, stats.heat_transfer)
		end
		Self:next_to_transfer()
	end
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
---@field const ComponentVent|ComponentExchanger|ComponentFuel_rod|ComponentCooling_cell|ComponentPlating
---@field next_transfer number
---@field x integer
---@field y integer
---@field around IC2Component[]
---@field heat_production number
---@field heat number
---@field max_heat number
---@field health number
---@field adjacent_rod number
---@field on_type string
local IC2Component = {}
IC2Component.__index = IC2Component

---@param item LuaItemStack
function IC2Component.new(item, x, y)
	local component = setmetatable({
		type = ComponentType(item.name),
		name = item.name,
		x = x,
		y = y
	}, IC2Component)
	component.const = COMPONENT_CONST[component.type][component.name]
	component.max_heat = component.const.maxhealth
	init(component)
	if ON[component.name] then
		component.on_type = component.name
	else
		component.on_type = component.type
	end
	--c.on_type = on[c.name] or on[c.type]
	return component
end


function IC2Component:on(core, reactor)
	ON[self.on_type](self, core, reactor)
end

---@param heat number
function IC2Component:set_heat(heat)
	self.heat = math.max(heat, 0)
end

function IC2Component:get_pos()
	return self.x, self.y
end

---@param around IC2Component[]
function IC2Component:set_around(around)
	self.around = around
end

function IC2Component:next_to_transfer()
	---@type number
	self.next_transfer = next(self.around, self.next_transfer) or next(self.around)
	return self.next_transfer
end

function IC2Component:get_current_adjacent()
	return self.around[self.next_transfer]
end


---@param heat number
function IC2Component:remove_heat(heat)
	self.heat = math.max(self.heat - heat, 0)
	return self.heat
end

---@param heat number
function IC2Component:add_heat(heat)
	self.heat = math.max(self.heat + heat, 0)
	return self.heat
end

---@param truc IC2Component|IC2Reactor
---@param heat number
function IC2Component:transfer_to(truc, heat)
	self:add_heat(-heat)
	truc:add_heat(heat)
end

function IC2Component:calc_health()
	self.health = math.min((self.max_heat - self.heat)/self.max_heat, 0)
end
function IC2Component:is_overheat()
	return self.heat >= self.max_heat
end

return IC2Component
