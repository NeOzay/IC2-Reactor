local Component = require("scripts.components")

---@param rod IC2Component
---@param adjacents_rod number
local function heat_calculation(rod, adjacents_rod)
	local function efficiency(n)
		return n * (n + 1) * 2
	end
	local stats = rod.const
	return efficiency(stats.self_neutron + adjacents_rod) * stats.multiplier
end

---@param rod IC2Component
local function energy_calculation(rod)
	local stats = rod.const
	return REACTOR_CONST.power * (stats.self_neutron + rod.adjacent_rod) * stats.multiplier
end

local function sort_components(grid)
	local order = {}
	for key in pairs(grid) do
		table.insert(order, key)
	end

	table.sort(order)
	return order
end

---@class IC2Layout
---@field reactor IC2Reactor
---@field grid table<number, IC2Component>
---@field width number
---@field height number
---@field has_rod boolean
---@field energy number
local Layout = {}
Layout.__index = Layout

---@return IC2Layout
function Layout.new(reactor, width, height)
	local layout = setmetatable({
		reactor = reactor,
		width = width,
		height = height,
		order = {}
	}, Layout)
	layout.grid = {}
	layout.energy = 0
	global.class_instances.IC2Layout[layout] = true
	return layout
end

function Layout:insert_component(item, x, y)
	self.grid[x + (y-1)*self.width] = Component.new(self.reactor, item, x, y)
end

function Layout:remove_component(x, y)
	local component = self.grid[x + (y-1)*self.width]
	self.grid[x + (y-1)*self.width] = nil
	return component
end

---@param component IC2Component
function Layout:update(component)
	---@type IC2Component[]
	local around = {}

	if component.type == "exchanger" or component.type == "fuel-rod" then
		local x, y = component:get_pos()
		local loop = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
		for i, offset in pairs(loop) do
			local around_comp = self:get_component(x + offset[1], y + offset[2])
			if around_comp then
				if ((around_comp.type == "vent" and around_comp.name ~= "component-heat-vent") or around_comp.type == "exchanger" or around_comp.type == "cooling-cell") then
					around[i] = around_comp
				elseif around_comp.type == "fuel-rod" and component.type == "fuel-rod" then
					component.adjacent_rod = component.adjacent_rod + 1
				end
			end
		end
		component.next_transfer = next(around)
		if component.type == "fuel-rod" then
			self.has_rod = true
			component.heat_production = heat_calculation(component, component.adjacent_rod)
			component.energy = energy_calculation(component)
			self.energy = self.energy + component.energy
		end
	elseif component.name == "component-heat-vent" then
		local x, y = component:get_pos()
		local loop = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
		for i, offset in pairs(loop) do
			local around_comp = self:get_component(x + offset[1], y + offset[2])
			if around_comp and around_comp.type == "vent" and around_comp.name ~= "component-heat-vent" then
				around[i] = around_comp
			end
		end
	elseif component.type == "plating" then
		--self.IC2Reactor_Core.max_core_heat = self.IC2Reactor_Core.max_core_heat + component.const.maxhealth
		--self.IC2Reactor_Core.explosion_radius = self.IC2Reactor_Core.explosion_radius + component.const.explosion
	end
	component:set_around(around)
end

function Layout:update_all()
		self.energy = 0
		self.has_rod = false

	for index, component in pairs(self.grid) do
		self:update(component)
	end
end

---@return IC2Component?
function Layout:get_component(x, y)
	return self.grid[x + (y - 1) * self.width]
end

---@param reactor IC2Reactor
---@return number
function Layout:on_tick(reactor)
	local energy = 0
	for _, component in ipairs(self.grid) do
		energy = energy + (component:on() or 0)
	end
	return energy
end
return Layout
