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
---@field component_map table<IC2Component, number>
---@field width number
---@field height number
---@field rod_count integer
---@field energy number
local Layout = {}
Layout.__index = Layout

function Layout.restore()
	for instance in pairs(global.class_instances.IC2Layout) do
		setmetatable(instance, Layout)
	end
end

---@return IC2Layout
function Layout.new(reactor, width, height)
	local layout = setmetatable({
		reactor = reactor,
		width = width,
		height = height,
		order = {},
		rod_count = 0
	}, Layout)
	layout.grid = {}
	layout.component_map = {}
	layout.energy = 0
	global.class_instances.IC2Layout[layout] = true
	return layout
end

---@param self IC2Layout
---@param x integer
---@param y integer
local function grid_index(self, x, y)
	return x + (y - 1) * self.width
end

---@param x number
---@param y number
---@return boolean
function Layout:valid_position(x, y)
	return not (x <= 0 or x > self.width or y <= 0 or y > self.height)
end

---@param item LuaItemStack
---@param x number
---@param y number
---@return boolean
function Layout:insert_component(item, x, y)
	local index = grid_index(self, x, y)
	if not self:valid_position(x, y) and not self.grid[index] then return false end
	local component = Component.new(self.reactor, item, x, y)
	self.grid[index] = component
	self.component_map[component] = index

	if component.type == "fuel-rod" then
		self.rod_count = self.rod_count + 1
	end
	self:update(x,y)
	return true
end

---@param x number
---@param y number
---@return IC2Component?
function Layout:remove_component_at(x, y)
	local component = self:get_component(x, y)
	if component then
		local index = self.component_map[component]
		self.grid[index] = nil
		self.component_map[component] = nil
		if component.type == "fuel-rod" then
			self.rod_count = math.max(self.rod_count - 1, 0)
		end
	end
	self:update(x, y)
	return component
end

---@param component IC2Component
function Layout:remove_component(component)
	local index = self.component_map[component]
	if index then
		self.grid[index] = nil
		self.component_map[component] = nil
		if component.type == "fuel-rod" then
			self.rod_count = math.max(self.rod_count - 1, 0)
		end
	end
	self:update(component.x, component.y)
end

---@param self IC2Layout
---@param x number|IC2Component
---@param y number?
---@return IC2Component[]
local function get_neighbor_component(self, x, y)
	if not (type(x) == "number" or type(y) == "number") then
		y = x.y
		x = x.x
	end

	local neighbor = {}
	local sides = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
	for _, side in pairs(sides) do
		local around_comp = self:get_component(x + side[1], y + side[2])
		if around_comp then
			table.insert(neighbor, around_comp)
		end
	end
	return neighbor
end

---@param self IC2Layout
---@param x number|IC2Component
---@param y number?
local function update(self, x, y)
	local component
	if type(x) == "number" or type(y) == "number" then
		component = self:get_component(x, y)
	else ---@cast x IC2Component
		component = x
		x = component.x
		y = component.y
	end
	if not component then return end

	---@type IC2Component[]
	local around = {}
	local neighbor_components = get_neighbor_component(self, component)

	if component.type == "exchanger" or component.type == "fuel-rod" then
		for i, around_comp in pairs(neighbor_components) do
			if ((around_comp.type == "vent" and around_comp.name ~= "component-heat-vent") or around_comp.type == "exchanger" or around_comp.type == "cooling-cell") then
				around[i] = around_comp
			elseif around_comp.type == "fuel-rod" and component.type == "fuel-rod" then
				component.adjacent_rod = component.adjacent_rod + 1
			end
		end
		component.next_transfer = component.next_transfer or next(around)
		if component.type == "fuel-rod" then
			component.heat_production = heat_calculation(component, component.adjacent_rod)
			component.energy_prod = energy_calculation(component)
		end
	elseif component.name == "component-heat-vent" then
		for i, around_comp in pairs(neighbor_components) do
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
	self.rod_count = 0

	for index, component in pairs(self.grid) do
		update(self, component)
		if component.type == "fuel-rod" then
			self.rod_count = self.rod_count + 1
		end
	end
end

function Layout:update(x, y)
	local neighbors = get_neighbor_component(self, x, y)
	update(self, x, y)
	for _, neighbor in pairs(neighbors) do
		update(self, neighbor)
	end
end

---@return IC2Component?
function Layout:get_component(x, y)
	if not self:valid_position(x, y) then return end
	return self.grid[x + (y - 1) * self.width]
end

---@return number
function Layout:on_tick()
	local energy = 0
	for _, component in pairs(self.grid) do
		if component:is_overheat() then
			self:remove_component(component)
		else
			energy = energy + (component:on() or 0)
		end
	end
	return energy
end

return Layout
