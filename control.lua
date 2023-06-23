require("util")
require("scripts.const")
local Reactor = require("scripts.reactor")
local Fluid_reactor = require("scripts.fluid_reactor")
local Reactor_core = require("scripts.reactor_core")
local Text_rendering = require"scripts.text_rendering"

if script.active_mods["gvv"] then require("__gvv__.gvv")() end

---@param event EventData.on_built_entity
local function buildReactor(event)
	local reactor ---@type IC2Reactor
	if event.created_entity.name == "ic2-reactor-main" then
		reactor = Reactor.new(event.created_entity)
	elseif event.created_entity.name == "ic2-fluid-reactor-main" then
		reactor = Fluid_reactor.new(event.created_entity)
	end
	local success = reactor:setup()
	if not success then
		game.get_player(event.player_index).print("oh noooo!!")
	end
end

---@param event EventData.on_pre_player_mined_item
local function removeReactor(event)
	Reactor.getIC2Reactor(event.entity):remove(event.player_index)
end

local function init()
	---@type IC2Reactor[]
	global.reactors = global.reactors or {}
end

local function load()
	-- logging(serpent.block(global.reactorList) or "test")
	for _, reactor in pairs(global.reactors) do
		Reactor.restore(reactor)
	end
end

---@param ticks NthTickEventData
local function ontick(ticks)
	for key, reactor in pairs(global.reactors) do
		reactor:on_tick()
	end
end


script.on_init(init)
script.on_configuration_changed(init)
script.on_load(load)

script.on_nth_tick(60, ontick)



local events = defines.events
script.on_event(events.on_built_entity, buildReactor, {{filter = "name", name = "ic2-reactor-main",mode = "or"},{filter = "name", name = "ic2-fluid-reactor-main"}})
script.on_event(events.on_pre_player_mined_item, removeReactor, {{filter = "name", name = "ic2-reactor-main"}})
script.on_event(events.on_entity_died, removeReactor, {{filter = "name", name = "ic2-reactor-main"}})


script.on_event(events.on_player_joined_game, function (event)
	game.players[event.player_index].cheat_mode = true
	game.players[event.player_index].force.research_all_technologies()
end)
