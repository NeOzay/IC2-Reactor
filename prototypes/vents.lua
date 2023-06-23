data:extend({
	{
		type = "item",
		name = "heat_vent",
		icon = "__IC2-Reactor__/assets/heat_vent.png",
		icon_size = 16,
		placed_as_equipment_result = "heat_vent",
		subgroup = "vents",
		stack_size = 1,
		default_request_amount = 1
	},
	{
		type = "battery-equipment",
		name = "heat_vent",
		sprite = {
			filename = "__IC2-Reactor__/assets/heat_vent.png",
			width = 16,
			height = 16,
			priority = "medium"
		},
		shape = {width = 1, height = 1, type = "full"},
		energy_source = {
			type = "electric",
			buffer_capacity = "1000J", -- "20MJ",
			input_flow_limit = "0W",
			output_flow_limit = "0W",
			usage_priority = "tertiary"
		},
		categories = {"reactor-component"}
	}
})
