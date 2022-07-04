local reactor_icon = "__base__/graphics/entity/nuclear-reactor/reactor.png"
local assets = "__IC2-Reactor__/assets/"

local empty_sprite = {
	filename = "__core__/graphics/empty.png",
	flags = {"always-compressed"},
	priority = "extra-high",
	frame_count = 1,
	width = 1,
	height = 1
}

local no_base_connector_template = util.table.deepcopy(universal_connector_template)
no_base_connector_template. connector_main   = nil --remove base
no_base_connector_template. connector_shadow = nil --remove base shadow

local connector = circuit_connector_definitions.create(no_base_connector_template,{{
	-- The "variation" determines in which direction the connector is drawn. I look
	-- at the file "factorio\data\base\graphics\entity\circuit-connector\hr-ccm-universal-04a-base-sequence.png"
	-- and count from the left top corner starting with 0 to get the angle I want.
	variation     = 25,
	main_offset   = util.by_pixel(7.0, -4.0), -- Converts pixels to tile fractions
	shadow_offset = util.by_pixel(7.0, -4.0), -- automatically for easier shifting.
	show_shadow   = true
}})

local interface_led = {
	filename = "__base__/graphics/entity/combinator/activity-leds/decider-combinator-LED-S.png",
	width = 8,
	height = 8,
	frame_count = 1,
	--shift = {-0.28125, -0.34375}
	shift = {-0.15, -0.24},
	scale = 0.3,
}

local red_point = {x=6.9,y=10.8}
local green_point = {x=-6.1,y=10.8}
local interface_connection = {
	shadow = {
		red =   util.by_pixel(red_point.x+16, red_point.y+12.5),--{0.796875, 0.5},
		green = util.by_pixel(green_point.x+16, green_point.y+12.5)--{0.203125, 0.5},
	},
	wire = {
		red =   util.by_pixel(red_point.x, red_point.y),--{0.296875, 0.0625},
		green = util.by_pixel(green_point.x, green_point.y)--{-0.296875, 0.0625},
	}
}

-- reactor
data:extend({
	{
		type = "container",
		name = "ic2-reactor-container",
		icon = reactor_icon,
		icon_size = 32,
		picture = empty_sprite,
		inventory_size = 1,
		selectable_in_game = true,
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		flags = {"not-blueprintable"},
		selection_priority=60
	},
	{
		type = "accumulator",
		name = "ic2-reactor-main",
		icon = reactor_icon,
		icon_size = 32,
		max_health = 500,
		vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
		charge_cooldown    = 1,
		discharge_cooldown = 1,
		picture = {
			layers = {
				{
					filename = reactor_icon,
					width = 154,
					height = 158,
					shift = util.by_pixel(-6, -6),
					hr_version = {
						filename = "__base__/graphics/entity/nuclear-reactor/hr-reactor.png",
						width = 302,
						height = 318,
						scale = 0.5,
						shift = util.by_pixel(-5, -7)
					}
				},
				{
					filename = assets.."reactor/reactor-shadow.png",
					width = 263,
					height = 162,
					shift = {1.625, 0},
					draw_as_shadow = true,
					hr_version = {
						filename = assets.."reactor/hr-reactor-shadow.png",
						width = 525,
						height = 323,
						scale = 0.5,
						shift = {1.625, 0},
						draw_as_shadow = true
					}
				}
			}
		},
		energy_source = {
			type                   = 'electric',
			usage_priority         = 'primary-output',
			input_flow_limit       = '0kW',
			buffer_capacity        = "100MJ",
			output_flow_limit = "100MW"
		},
		
			working_sound = {
			sound = {
				type = "sound",
				name = "NuclearReactorLoop",
				category = "game-effect",
				aggregation = {
					max_count = 1,
					remove = false,
				},
				filename = assets.."NuclearReactorSound/NuclearReactorLoop.ogg",
				volume = 2
		
			},
			idle_sound = { filename = "__base__/sound/idle1.ogg", volume = 0.6 },
			apparent_volume = 2.5,
		},

		circuit_wire_max_distance = default_circuit_wire_max_distance,
    
		-- Here I use the data that I prepared above.
		circuit_wire_connection_point = connector.points ,
		circuit_connector_sprites     = connector.sprites,
		collision_box = {{-2, -2}, {2, 2}},
		selection_box = {{-2, -2}, {2, 2}},
		minable = {mining_time = 1, result = "ic2-reactor-main-item"},
		selection_priority=40
	},
	{
		type = "constant-combinator",
		name = "ic2-reactor-interface",
		selection_priority = 255,
		icon = reactor_icon,
		icon_size = 32,
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		item_slot_count = 14,
		sprites = {
			north = empty_sprite,
			east  = empty_sprite,
			south = empty_sprite,
			west  = empty_sprite,
		},
		activity_led_sprites = {
			north = util.draw_as_glow(interface_led),
			east  = util.draw_as_glow(interface_led),
			south = util.draw_as_glow(interface_led),
			west  = util.draw_as_glow(interface_led),
		},
		activity_led_light = {
			intensity = 0.4,
			size = 0.3,
			color = {r = 0.02, g = 0.05, b = 0.55}
		},
		activity_led_light_offsets = {
			interface_led.shift,
			interface_led.shift,
			interface_led.shift,
			interface_led.shift,
		},circuit_wire_connection_points = {
			interface_connection,
			interface_connection,
			interface_connection,
			interface_connection,
		},
		circuit_wire_max_distance = 7.5,
		order = "z",
	}
})

-- fuid reactor
data:extend({
	{
		type = "simple-entity-with-owner",
		name = "ic2-fluid-reactor-main",
		icon = reactor_icon,
		icon_size = 32,
		max_health = 500,
		vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
		picture = {
			layers = {
				{
					filename = reactor_icon,
					width = 154,
					height = 158,
					shift = util.by_pixel(-6, -6),
					hr_version = {
						filename = assets.."reactor/hr-reactor2.png",
						width = 302,
						height = 318,
						scale = 0.5,
						shift = util.by_pixel(-5, -7)
					}
				},
				{
					filename = assets.."reactor/reactor-shadow.png",
					width = 263,
					height = 162,
					shift = {1.625, 0},
					draw_as_shadow = true,
					hr_version = {
						filename = assets.."reactor/hr-reactor-shadow.png",
						width = 525,
						height = 323,
						scale = 0.5,
						shift = {1.625, 0},
						draw_as_shadow = true
					}
				}
			}
		},

		collision_box = {{-2, -2}, {2, 2}},
		selection_box = {{-2, -2}, {2, 2}},
		minable = {mining_time = 1, result = "ic2-fluid-reactor-main-item"},
		selection_priority=40
	},
	{
		type = "storage-tank",
		name = "ic2-fluid-reactor-input",
		collision_mask = {"item-layer","ghost-layer"},
		icon = reactor_icon,
		icon_size = 32,
		flags = {"not-blueprintable"},
		selectable_in_game = true,
		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		--drawing_box = {{-1.4,-1.4},{-1,-1}}, --doesnt affect alt-info-overlay
		fluid_box = {
			base_area = 50,
			pipe_covers = pipecoverspictures(),
			pipe_connections = {
				{
					type = "input",
					position = {0, 0.9}
				}
			}
		},
		window_bounding_box = {{0, -0.25}, {0, 0.25}},
		pictures = {
			picture = {
				filename = assets.."reactor/fluid_tank_input.png",
				priority = "extra-high",
				width = 163,
				height = 87,
				scale = 0.5,
				shift = util.by_pixel(8,3)
			},
			fluid_background = {
				filename = assets.."reactor/fluid_background_input.png",
				priority = "extra-high",
				width = 10,
				height = 9,
			},
			window_background = {
				filename = assets.."reactor/fluid_tank_background_input.png",
				priority = "extra-high",
				width = 19,
				height = 18,
				scale = 0.5
				--   shift = {0.1875, 0}
			},
			flow_sprite = {
				filename = "__base__/graphics/entity/pipe/fluid-flow-low-temperature.png",
				priority = "extra-high",
				width = 160,
				height = 20
			},
			gas_flow = empty_sprite
		},
		flow_length_in_ticks = 360,
		circuit_wire_max_distance = 0,
		order = "z",
	},
	{
		type = "storage-tank",
		name = "ic2-fluid-reactor-output",
		collision_mask = {"item-layer","ghost-layer"},
		icon = reactor_icon,
		icon_size = 32,
		flags = {"not-blueprintable"},
		selectable_in_game = true,
		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		--drawing_box = {{-1.4,-1.4},{-1,-1}}, --doesnt affect alt-info-overlay
		fluid_box = {
			base_area = 50,
			pipe_covers = pipecoverspictures(),
			pipe_connections = {
				{
					type = "input",
					position = {0, 0.9}
				}
			}
		},
		window_bounding_box = {{0, -0.25}, {0, 0.25}},
		pictures = {
			picture = {
				filename = assets.."reactor/fluid_tank_output.png",
				priority = "extra-high",
				width = 139,
				height = 87,
				scale = 0.5,
				shift = util.by_pixel(-12,3)
			},
			fluid_background = {
				filename = assets.."reactor/fluid_background_output.png",
				priority = "extra-high",
				width = 11,
				height = 24,
			},
			window_background = {
				filename = assets.."reactor/fluid_tank_background_output.png",
				priority = "extra-high",
				width = 25,
				height = 47,
				scale = 0.5
				--   shift = {0.1875, 0}
			},
			flow_sprite = {
				filename = "__base__/graphics/entity/pipe/fluid-flow-low-temperature.png",
				priority = "extra-high",
				width = 160,
				height = 20
			},
			gas_flow = empty_sprite
		},
		flow_length_in_ticks = 360,
		circuit_wire_max_distance = 0,
		order = "z",
	}
})
