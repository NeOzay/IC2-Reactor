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
---@param adjacents_rod number
local function energy_calculation(rod, adjacents_rod)
	local stats = rod.const
	return REACTOR_CONST.power * (stats.self_neutron + adjacents_rod) * stats.multiplier
end

local function sort_components(grid)
	local order = {}
	for key in pairs( grid) do
		table.insert(order, key)
	end

	table.sort(order)
	return order
end

---@class Layout
---@field grid table<number, IC2Component>
---@field order number[]
---@field width number
---@field height number
---@field has_rod boolean
---@field energy number
local Layout = {}
Layout.__index = Layout

---@return Layout
function Layout.new(width, height)
	local layout = setmetatable({
		width = width,
		height = height,
		order = {}
	}, Layout)
	layout.grid = {}
	layout.energy = 0
	return layout
end

function Layout:insert_component(item)
	
end

---@param item LuaItemStack
function Layout:update(item)
	self.energy = 0
	self.has_rod = false
	local grid = self.grid
	local section = 0
	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local equipment = self.raw_grid.get {x, y}
			if equipment then
				local component = Component.new(equipment)
				grid[section] = component
			else
				grid[section] = nil
			end
			section = section + 1
		end
	end

	for index, component in pairs(self.grid) do
		---@type IC2Component[]
		local around = {}

		if component.type == "exchanger" or component.type == "fuel-rod" then
			local pos = component.position
			local loop = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
			for i, p in pairs(loop) do
				local around_comp = self:get_component(pos.x + p[1], pos.y + p[2])
				if around_comp then
					if ((around_comp.type == "vent" and around_comp.name ~= "component-heat-vent") or around_comp.type == "exchanger" or around_comp.type == "cooling-cell")  then
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
				component.heat = energy_calculation(component, component.adjacent_rod)
				self.energy = self.energy + component.heat
				log(component.name .. ", " .. component.heat_production .. ", " .. component.heat .. ", " ..
								    component.adjacent_rod)
			end
		elseif component.name == "component-heat-vent" then
			local pos = component.position
			local loop = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
			for i, p in pairs(loop) do
				local around_comp = self:get_component(pos.x + p[1], pos.y + p[2])
				if around_comp and around_comp.type == "vent" and around_comp.name ~= "component-heat-vent" then
					around[i] = around_comp
				end
			end
		elseif component.type == "plating" then
			self.IC2Reactor_Core.max_core_heat = self.IC2Reactor_Core.max_core_heat + component.const.maxhealth
			self.IC2Reactor_Core.explosion_radius = self.IC2Reactor_Core.explosion_radius + component.const.explosion
		end
		component:set_around(around)
	end
	self.order = sort_components(self.grid)
end

---@return IC2Component?
function Layout:get_component(x, y)
	return self.grid[x + (y - 1) * self.width]
end


---@param option LuaEquipmentGrid.take_param
---@return SimpleItemStack
function Layout:remove_component(option)
	local item = self.raw_grid.take{
		position = option.position,
		equipment = option.equipment,
		by_player = option.by_player
	}
	self:update(self.item)
	return item
end



return Layout
