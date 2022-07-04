local components = {}

---@type table<string, fun(Self:Component)>
components.init = {
	["fuel-rod"] = function(Self)
		Self.adjacent_rod = 0
	end
}

---@type table<string, fun(Self:Component, core:IC2Reactor_Core, reactor:IC2Reactor)>
components.on = {
	["fuel-rod"] = function(Self,core, reactor)
		if Self:is_overheat() then
			core.layout:remove_component({equipment = Self.equipment})
			return
		end
		if reactor.has_redstone_signal then
			local around_component = Self:get_current_adjacent()
			Self:add_heat(1)
			if around_component and around_component:is_valid() then
				Self:next_to_transfer()
				around_component:add_heat(Self.heat_production)
			else
				core.core_heat = core.core_heat + Self.heat_production
			end
		end
	end,

	exchanger = function(Self, core)
		if Self:is_overheat() then
			core.layout:remove_component({equipment = Self.equipment})
			return
		end
		local stats = Self.stats
		local around_component = Self:get_current_adjacent()

		if around_component and around_component:is_valid() then
			local heat_comp = Self:get_heat_percent()
			local heat_around = around_component:get_heat_percent()
			if heat_comp < heat_around then
				around_component:transfer_to(Self,stats.heat_transfer)
			elseif heat_comp > heat_around then
				Self:transfer_to(around_component,stats.heat_transfer)
			end
			Self:next_to_transfer()
		end

		local heat_comp = Self:get_heat_percent()
		local heat_core = core:get_heat()
		if heat_comp < heat_core then
			core:transfer_to(Self,stats.heat_pull)
		elseif heat_comp > heat_core then
			Self:transfer_to(core,stats.heat_pull)
		end
	end,

	vent = function(Self, core)
		if Self:is_overheat() then
			core.layout:remove_component({equipment = Self.equipment})
			return
		end
		local stats = Self.stats
		Self:remove_heat(stats.heat_dissipated)
	end,

	["cooling-cell"] = function(Self, core)
		if Self:is_overheat() then
			core.layout:remove_component({equipment = Self.equipment})
			return
		end
	end,

	["plating"] = function(Self, core)

	end
}

components.on["reactor-heat-vent"] = function (Self, core)
	if Self:is_overheat() then
		core.layout:remove_component({equipment = Self.equipment})
		return
	end
	local stats = Self.stats
	local core_heat = core:get_heat()
	if core_heat >= stats.heat_pull then
		core:transfer_to(Self, stats.heat_pull)
		Self:remove_heat(stats.heat_dissipated)
	end
end
components.on["overclocked-heat-vent"] = function (Self, core)
	if Self:is_overheat() then
		core.layout:remove_component({equipment = Self.equipment})
		return
	end
	local stats = Self.stats
	local core_heat = core:get_heat()
	Self:remove_heat(stats.heat_dissipated)
	if core_heat >= stats.heat_pull then
		core:transfer_to(Self,stats.heat_pull)
	end
end
components.on["component-heat-vent"] = function (Self, core)
	local stats = Self.stats
	for index, around_component in pairs(Self.around) do
		around_component:remove_heat(stats.heat_dissipated)
	end
end

components.on["reactor-heat-exchanger"] = function (Self, core)
	if Self:is_overheat() then
		core.layout:remove_component({equipment = Self.equipment})
		return
	end
	local stats = Self.stats
	local heat_comp = Self:get_heat_percent()
	local heat_core = core:get_heat()
	if heat_comp < heat_core then
		core:transfer_to(Self,stats.heat_pull)
	elseif heat_comp > heat_core then
		Self:transfer_to(core,stats.heat_pull)
	end
end

components.on["component-heat-exchanger"] = function (Self, core)
	if Self:is_overheat() then
		core.layout:remove_component({equipment = Self.equipment})
		return
	end
	local stats = Self.stats
	local around_component = Self:get_current_adjacent()

	if around_component and around_component:is_valid() then
		local heat_comp = Self:get_heat_percent()
		local heat_around = around_component:get_heat_percent()
		if heat_comp < heat_around then
			around_component:transfer_to(Self,stats.heat_transfer)
		elseif heat_comp > heat_around then
			Self:transfer_to(around_component,stats.heat_transfer)
		end
		Self:next_to_transfer()
	end
end

local on = components.on
local init = components.init

---@class Component
---@field type string
---@field name string
---@field equipment LuaEquipment
---@field stats vent|exchanger|fuel_rod|cooling_cell|plating
---@field next_transfer number
---@field position Position
---@field around Component[]
---@field heat_production number
---@field energy number
---@field max_heat number
---@field adjacent_rod number
---@field on_type string
local Component = {}
Component.__index = Component

---@param LuaEquipment LuaEquipment
function Component.new(LuaEquipment)
	---@type Component
	local c = {
		type = ComponentType(LuaEquipment.name),
		name = LuaEquipment.name,
		position = LuaEquipment.position,
		equipment = LuaEquipment,
		max_heat = LuaEquipment.max_energy
	}
	c.stats = component_const[c.type .. "s"][c.name]
	setmetatable(c, Component)
	c:init()
	if on[c.name] then
		c.on_type = c.name
	else
		c.on_type = c.type
	end
	--c.on_type = on[c.name] or on[c.type]
	return c
end

function Component:init()
	if init[self.type] then
		init[self.type](self)
	end
end

function Component:on(core, reactor)
	on[self.on_type](self, core, reactor)
end

---@param heat number
function Component:set_heat(heat)
	self.equipment.energy = heat
end

function Component:get_pos()
	return self.equipment.position
end

---@param around Component[]
function Component:set_around(around)
	self.around = around
end

function Component:next_to_transfer()
	---@type number
	self.next_transfer = next(self.around, self.next_transfer) or next(self.around)
	return self.next_transfer
end

function Component:get_current_adjacent()
	return self.around[self.next_transfer]
end

function Component:get_heat()
	return self.equipment.energy
end

function Component:get_heat_percent()
	return self:get_heat() / self.max_heat
end

---@param heat number
function Component:remove_heat(heat)
	self.equipment.energy = math.min(math.max(self.equipment.energy - heat, 0),self.max_heat)
	return self.equipment.energy
end

---@param heat number
function Component:add_heat(heat)
	self.equipment.energy = math.max(math.min(self.equipment.energy + heat, self.max_heat),0)
	return self.equipment.energy
end

---@param truc Component|IC2Reactor_Core
---@param heat number
function Component:transfer_to(truc, heat)
	self:remove_heat(heat)
	truc:add_heat(heat)
end

function Component:is_overheat()
	return self:get_heat() >= self.max_heat
end

function Component:is_valid()
	return self.equipment.valid
end

return Component
