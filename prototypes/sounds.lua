local soundPath = "__IC2-Reactor__/assets/NuclearReactorSound/"

data:extend({
	{
		type = "sound",
		name = "Geiger",
		category = "game-effect",
		allow_random_repeat = true,
		audible_distance_modifier = 0.5,
		aggregation = {
			max_count = 1,
			remove = false,
		},
		variations = {
			{
				filename = soundPath.."GeigerLowEU.ogg"
			},
			{
				filename = soundPath.."GeigerMedEU.ogg"
			},
			{
				filename = soundPath.."GeigerHighEU.ogg"
			},
			{
				filename = soundPath.."GeigerHighEU.ogg"
			},
			{
				filename = soundPath.."GeigerMedEU.ogg"
			},
		},
	},
	{
		type = "sound",
		name = "NuclearReactorLoop",
		category = "game-effect",
		aggregation = {
			max_count = 1,
			remove = false,
		},
		filename = soundPath.."NuclearReactorLoop.ogg",
		volume = 1

	}
})