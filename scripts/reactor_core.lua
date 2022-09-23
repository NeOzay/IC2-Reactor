local Component = require("scripts.components")

---@param item LuaItemStack
function getIC2ReactorCore(item)
	if global.CoreList[1000 - item.durability] then
		return global.CoreList[1000 - item.durability]
	end
end

---@param rod Component
---@param adjacents_rod number
local function heat_calculation(rod, adjacents_rod)
	local function efficiency(n)
		return n * (n + 1) * 2
	end
	local stats = rod.stats
	return efficiency(stats.self_neutron + adjacents_rod) * stats.multiplier
end
---@param rod Component
---@param adjacents_rod number
local function energy_calculation(rod, adjacents_rod)
	local stats = rod.stats
	return reactor_const.power * (stats.self_neutron + adjacents_rod) * stats.multiplier
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
---@field grid table<number, Component>
---@field order number[]
---@field item LuaItemStack
---@field IC2Reactor_Core IC2Reactor_Core
---@field width number
---@field height number
---@field raw_grid LuaEquipmentGrid
---@field has_rod boolean
---@field energy number
local Layout = {}
Layout.__index = Layout

---@param LuaItemStack LuaItemStack
---@return Layout
function Layout.new(LuaItemStack)
	local LuaEquipmentGrid = LuaItemStack.grid
	---@type Layout
	local l = {
		raw_grid = LuaEquipmentGrid,
		item = LuaItemStack,
		width = LuaEquipmentGrid.width,
		height = LuaEquipmentGrid.height,
		order = {}
	}
	---@type table<number,Component>
	local grid = {}
	l.grid = grid
	l.energy = 0
	l.IC2Reactor_Core = getIC2ReactorCore(LuaItemStack)
	l.IC2Reactor_Core.max_core_heat = reactor_const.maxhealth
	l.IC2Reactor_Core.explosion_radius = 0
	return setmetatable(l, Layout)
end

---@param item LuaItemStack
function Layout:update(item)
	if not isValid(self.raw_grid) or not isValid(self.item) then
		self.raw_grid = item.grid
		self.item = item
	end
	self.energy = 0
	self.IC2Reactor_Core.max_core_heat = reactor_const.maxhealth
	self.IC2Reactor_Core.explosion_radius = 0
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
		---@type Component[]
		local around = {}

		if component.type == "exchanger" or component.type == "fuel-rod" then
			local pos = component.position
			local loop = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
			for i, p in pairs(loop) do
				local around_comp = self:get_component(pos.x + p[1], pos.y + p[2])
				if around_comp then
					if ((around_comp.type == "vent" and around_comp.name ~= "component-heat-vent") or around_comp.type == "exchanger" or around_comp.type ==
									"cooling-cell")  then
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
				component.energy = energy_calculation(component, component.adjacent_rod)
				self.energy = self.energy + component.energy
				log(component.name .. ", " .. component.heat_production .. ", " .. component.energy .. ", " ..
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
			self.IC2Reactor_Core.max_core_heat = self.IC2Reactor_Core.max_core_heat + component.stats.maxhealth
			self.IC2Reactor_Core.explosion_radius = self.IC2Reactor_Core.explosion_radius + component.stats.explosion
		end
		component:set_around(around)
	end
	self.order = sort_components(self.grid)
end


function Layout:get_component(x, y)
	return self.grid[x + y * self.width]
end


---@param option LuaEquipmentGrid.take
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


---@class IC2Reactor_Core
---@field layout Layout
---@field item LuaItemStack
---@field index number
---@field energy number
---@field core_heat number
---@field max_core_heat number
---@field explosion_radius number
local IC2Reactor_Core = {}
IC2Reactor_Core.__index = IC2Reactor_Core

---@param core LuaItemStack
function IC2Reactor_Core.new(core)
	core.drain_durability(#global.CoreList + 1)
	---@type IC2Reactor_Core
	local c = {item = core, core_heat = 0}
	c.index = #global.CoreList + 1
	global.CoreList[#global.CoreList + 1] = c
	c.layout = Layout.new(c.item)
	return setmetatable(c, IC2Reactor_Core)
end

---@param item LuaItemStack
function IC2Reactor_Core.getIC2ReactorCore(item)
	if global.CoreList[1000 - item.durability] then
		return global.CoreList[1000 - item.durability]
	end
end

---@param item LuaItemStack
function IC2Reactor_Core:update(item)
	self.item = item
	self.layout:update(item)
	self.energy = self.layout.energy
	game.print(self.core_heat)
end

function IC2Reactor_Core:remove()
	global.CoreList[self.index] = nil
end

function IC2Reactor_Core:get_heat()
	return self.core_heat
end

function IC2Reactor_Core:get_heat_percent()
	return self.core_heat / self.max_core_heat
end

function IC2Reactor_Core:add_heat(heat)
	self.core_heat = self.core_heat + heat
end

function IC2Reactor_Core:remove_heat(heat)
	self.core_heat = math.max(self.core_heat - heat, 0)
end

---@param truc Component|IC2Reactor_Core
---@param heat number
function IC2Reactor_Core:transfer_to(truc, heat)
	self:remove_heat(heat)
	truc:add_heat(heat)
end

---@param reactor IC2Reactor
function IC2Reactor_Core:on_tick(reactor)
	for index, slot in ipairs(self.layout.order) do
		local component = self.layout.grid[slot]
		if component:is_valid() then
			component:on(self, reactor)
		else
			self:update(self.item)
		end
		
	end
end

IC2Reactor_Core.Layout = Layout
IC2Reactor_Core.Component = Component
return IC2Reactor_Core
