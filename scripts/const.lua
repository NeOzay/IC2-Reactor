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
		heat_transfer=heat_transfer,
		heat_pull = heat_pull,
		maxhealth = maxhealth
	}
end

---@alias vent {name:string, heat_dissipated:number, heat_pull:number, maxhealth:number}
---@alias exchanger {name:string, heat_transfer:number, heat_pull:number, maxhealth:number}
---@alias cooling_cell {name:string, maxhealth:number}
---@alias fuel_rod {name:string, maxhealth:number, multiplier:number, self_neutron:number}
---@alias plating {name:string, maxhealth:number, explosion:number}

---@type {vents:table<string, vent>, exchangers:table<string, exchanger>, cooling-cells:table<string, cooling_cell>, fuel_rods:table<string, fuel_rod>, platings:table<string, plating>}
component_const = {
	vents = {
		["heat-vent"] = vent("heat-vent", 6, 0, 1000),
		["advanced-heat-vent"] = vent("advanced-heat-vent", 12, 0, 1000),
		["reactor-heat-vent"] = vent("reactor-heat-vent", 5, 5, 1000),
		["overclocked-heat-vent"] = vent("overclocked-head-vent", 20, 36, 1000),
		["component-heat-vent"] = vent("component-heat-vent", 4, 0, 1000)
	},
	exchangers = {
		['heat-exchanger'] = exchanger("heat-exchanger",12,4,2500),
		["advanced-heat-exchanger"] = exchanger("advanced-heat-exchanger", 24,8,10000),
		["reactor-heat-exchanger"] = exchanger("reactor-heat-exchanger", 0, 72, 5000),
		["component-heat-exchanger"] = exchanger("component-heat-exchanger", 36,0,5000)
	},
	["cooling-cells"] = {
		["10k-cooling-cell"] = {name = "10k-cooling-cell", maxhealth = 10000},
		["30k-cooling-cell"] = {name = "30k-cooling-cell", maxhealth = 30000},
		["60k-cooling-cell"] = {name = "60k-cooling-cell", maxhealth = 60000}
	},
	["fuel-rods"] = {
		["uranium-fuel-rod"] = {name = "uranium-fuel-rod", maxhealth = 20000, multiplier= 1, self_neutron = 1},
		["dual-uranium-fuel-rod"] = {name = "dual-uranium-fuel-rod", maxhealth = 20000, multiplier = 2, self_neutron = 2},
		["quad-uranium-fuel-rod"] = {name = "quad-uranium-fuel-rod", maxhealth = 20000, multiplier = 4, self_neutron = 3}
	},
	platings = {
		["reactor-plating"] = {name = "reactor-plating", maxhealth = 1000, explosion  = -5},
		["containment-reactor-plating"] = {name = "containment-reactor-plating", maxhealth=500, explosion = -10},
		["heat-capacity-reactor-plating"] = {name = "heat-capacity-reactor-plating", maxhealth = 1700, explosion = -1}
	}
}

reactor_const = {
	maxhealth = 10000,
	power = 900000
}

signals_ID = {}
signals_ID.redstone = {type = "virtual", name = "redstone-signal"}

---@alias ComponentType '"vent"'|'"fuel-rod"'|'"exchanger"'|'"cooling-cell"'|'"plating"'

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
end

---@return boolean
function isValid(class)
	return class.valid
end

