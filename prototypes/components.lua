
local order = {uranium = 1, exchanger = 1, vent = 1, coolingCell = 1, plating = 1}
local list= {}
local function componentUranium(name, iconPath)
	table.insert(list,{
		type = "item",
		name = name,
		icon = "__IC2-Reactor__/assets/component/fuel_rod/"..iconPath..".png",
		icon_size = 16,
		placed_as_equipment_result = name,
		subgroup = "fuel-rods",
		stack_size = 1,
		default_request_amount = 64,
		order = tostring(order.uranium)
	})
	order.uranium = order.uranium + 1
end

local function componentExchanger(name, iconPath)
	table.insert(list,{
		type = "item",
		name = name,
		icon = "__IC2-Reactor__/assets/component/"..iconPath..".png",
		icon_size = 16,
		subgroup = "exchangers",
		stack_size = 1,
		default_request_amount = 64444,
		order = tostring(order.exchanger)
	})
	order.exchanger = order.exchanger + 1
end

local function componentVent(name,iconPath)
	table.insert(list,{
		type = "item",
		name = name,
		icon = "__IC2-Reactor__/assets/component/"..iconPath..".png",
		icon_size = 16,
		subgroup = "vents",
		stack_size = 1,
		default_request_amount = 64,
		order = tostring(order.vent)
	})
	order.vent = order.vent + 1
end

local function componentCoolingCell(name, iconPath)
	table.insert(list,{
		type = "item",
		name = name,
		icon = "__IC2-Reactor__/assets/component/"..iconPath..".png",
		icon_size = 16,
		subgroup = "cooling-cells",
		stack_size = 1,
		default_request_amount = 1,
		order = tostring(order.coolingCell)
	})
	order.coolingCell = order.coolingCell + 1
end

local function componentPlating(name, iconPath)
	table.insert(list,{
		type = "item",
		name = name,
		icon = "__IC2-Reactor__/assets/component/"..iconPath..".png",
		icon_size = 16,
		subgroup = "platings",
		stack_size = 1,
		default_request_amount = 1,
		order = tostring(order.plating)
	})
	order.plating = order.plating + 1
end

componentUranium("uranium-fuel-rod", "uranium")
componentUranium("dual-uranium-fuel-rod","dual_uranium")
componentUranium("quad-uranium-fuel-rod","quad_uranium")

componentExchanger("heat-exchanger","heat_exchanger")
componentExchanger("advanced-heat-exchanger","advanced_heat_exchanger")
componentExchanger("component-heat-exchanger","component_heat_exchanger")
componentExchanger("reactor-heat-exchanger","reactor_heat_exchanger")

componentVent("heat-vent","heat_vent")
componentVent("advanced-heat-vent", "advanced_heat_vent")
componentVent("overclocked-heat-vent", "overclocked_heat_vent")
componentVent("reactor-heat-vent", "reactor_heat_vent")
componentVent("component-heat-vent","component_heat_vent")

componentPlating("reactor-plating", "plating")
componentPlating("containment-reactor-plating", "containment_plating")
componentPlating("heat-capacity-reactor-plating", "heat_plating")

componentCoolingCell("10k-cooling-cell", "heat_storage")
componentCoolingCell("30k-cooling-cell", "tri_heat_storage")
componentCoolingCell("60k-cooling-cell", "hex_heat_storage")

data:extend(list)
