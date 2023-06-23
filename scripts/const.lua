---@param name string
---@param heat_dissipated number
---@param heat_pull number
---@param maxhealth number
local function vent(name, heat_dissipated, heat_pull, maxhealth)
	return {name = name, heat_dissipated = heat_dissipated, heat_pull = heat_pull, maxhealth = maxhealth}
end

---@param name string
---@param heat_transfer number
---@param heat_pull number
---@param maxhealth number
local function exchanger(name,heat_transfer,heat_pull,maxhealth)
	return {
		name = name,
		heat_transfer = heat_transfer,
		heat_pull = heat_pull,
		maxhealth = maxhealth
	}
end

---@class ComponentBase
---@field name string
---@field maxhealth number

---@class ComponentVent:ComponentBase
---@field heat_dissipated number
---@field heat_pull number

---@class ComponentExchanger:ComponentBase
---@field heat_transfer number
---@field heat_pull number

---@class ComponentCooling_cell:ComponentBase

---@class ComponentFuel_rod:ComponentBase
---@field multiplier number
---@field self_neutron number

---@class ComponentPlating:ComponentBase
---@field explosion number

--@type {vents:table<string, ComponentVent>, exchangers:table<string, ComponentExchanger>, cooling-cells:table<string, ComponentCooling_cell>, fuel_rods:table<string, ComponentFuel_rod>, platings:table<string, ComponentPlating>}
COMPONENT_CONST = {
	vent = {
		["heat-vent"] = vent("heat-vent", 6, 0, 1000),
		["advanced-heat-vent"] = vent("advanced-heat-vent", 12, 0, 1000),
		["reactor-heat-vent"] = vent("reactor-heat-vent", 5, 5, 1000),
		["overclocked-heat-vent"] = vent("overclocked-head-vent", 20, 36, 1000),
		["component-heat-vent"] = vent("component-heat-vent", 4, 0, 1000)
	},
	exchanger = {
		['heat-exchanger'] = exchanger("heat-exchanger",12,4,2500),
		["advanced-heat-exchanger"] = exchanger("advanced-heat-exchanger", 24,8,10000),
		["reactor-heat-exchanger"] = exchanger("reactor-heat-exchanger", 0, 72, 5000),
		["component-heat-exchanger"] = exchanger("component-heat-exchanger", 36,0,5000)
	},
	["cooling-cell"] = {
		["10k-cooling-cell"] = {name = "10k-cooling-cell", maxhealth = 10000},
		["30k-cooling-cell"] = {name = "30k-cooling-cell", maxhealth = 30000},
		["60k-cooling-cell"] = {name = "60k-cooling-cell", maxhealth = 60000}
	},
	["fuel-rod"] = {
		["uranium-fuel-rod"] = {name = "uranium-fuel-rod", maxhealth = 20000, multiplier= 1, self_neutron = 1},
		["dual-uranium-fuel-rod"] = {name = "dual-uranium-fuel-rod", maxhealth = 20000, multiplier = 2, self_neutron = 2},
		["quad-uranium-fuel-rod"] = {name = "quad-uranium-fuel-rod", maxhealth = 20000, multiplier = 4, self_neutron = 3}
	},
	plating = {
		["reactor-plating"] = {name = "reactor-plating", maxhealth = 1000, explosion  = -5},
		["containment-reactor-plating"] = {name = "containment-reactor-plating", maxhealth=500, explosion = -10},
		["heat-capacity-reactor-plating"] = {name = "heat-capacity-reactor-plating", maxhealth = 1700, explosion = -1}
	}
}

REACTOR_CONST = {
	maxhealth = 10000,
	power = 900000
}

REACTOR_GRID = { w = 9, h = 6 }
SIGNALS_ID = {}
SIGNALS_ID.redstone = {type = "virtual", name = "redstone-signal"}

---@alias ComponentType "vent"|"fuel-rod"|"exchanger"|"cooling-cell"|"plating"|"unknown"

---@param component string
---@return ComponentType
function ComponentType(component)
	if component:find("vent") then
		return "vent"
	end
	if component:find("fuel%-rod") then
		return "fuel-rod"
	end
	if component:find("exchanger") then
		return "exchanger"
	end
	if component:find("cooling%-cell") then
		return "cooling-cell"
	end
	if component:find("plating") then
		return 'plating'
	end
	return "unknown"
end

---@return boolean
function isValid(class)
	return class.valid
end

