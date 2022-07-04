require("util")
require("scripts.const")
local Reactor = require("scripts.reactor")
local Fluid_reactor = require("scripts.fluid_reactor")
local Reactor_core = require("scripts.reactor_core")
local Text_rendering = require"scripts.text_rendering"

if script.active_mods["gvv"] then require("__gvv__.gvv")() end

---@param event on_built_entity
local function buildReactor(event)
	if event.created_entity.name == "ic2-reactor-main" then
		Reactor.new(event.created_entity):setup()
	elseif event.created_entity.name == "ic2-fluid-reactor-main" then
		Fluid_reactor.new(event.created_entity):setup()
	end
end

---@param event on_pre_player_mined_item
local function removeReactor(event)
	Reactor.getIC2Reactor(event.entity):remove(event.player_index)
end

local function init()
	---@type IC2Reactor[]
	global.reactorList = global.reactorList or {}
	---@type IC2Reactor_Core[]
	global.CoreList = global.CoreList or {}
	-- logging(serpent.block(global.reactorList) or "test")
end

local function load()
	-- logging(serpent.block(global.reactorList) or "test")
	for _, reactor in pairs(global.reactorList) do
		setmetatable(reactor, Reactor)
		for _, text in pairs(reactor.texts) do
			setmetatable(text,Text_rendering)
		end
	end
	for _, core in pairs(global.CoreList) do
		setmetatable(core, Reactor_core)
		setmetatable(core.layout, Reactor_core.Layout)
		for _, component in pairs(core.layout.grid) do
			setmetatable(component,Reactor_core.Component)
		end
	end
end

---@param ticks NthTickEventData
local function ontick(ticks)
	for key, reactor in pairs(global.reactorList) do
		reactor:on_tick()
	end
end

---@param event on_equipment_inserted
local function equipmentUpdate2(event)
	if event.grid.prototype.name:find("reactor%-grid") then
		for index, reactor in pairs(global.reactorList) do
			local core = reactor:get_reactor_core()
			if reactor.item and reactor.item.grid and reactor.item.grid == event.grid then
				core:update(reactor.item)
			end
		end
	end
end

---@param event on_gui_closed
local function equipmentUpdate(event)
	if event.item and event.item.name:find("ic2%-reactor%-core") then
		Reactor_core.getIC2ReactorCore(event.item):update(event.item)
	end
end

---@param event on_player_crafted_item
local function craftCore(event)
	local item = event.item_stack
	if item.name:find("ic2%-reactor%-core") then
		Reactor_core.new(event.item_stack)
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

script.on_event(events.on_equipment_inserted, equipmentUpdate2)
script.on_event(events.on_equipment_removed, equipmentUpdate2)

script.on_event(events.on_player_crafted_item, craftCore)

script.on_event(events.on_gui_closed, equipmentUpdate)

script.on_event(events.on_player_armor_inventory_changed, function(event)
	local player = game.get_player(event.player_index)
	local inventoryArmor = player.get_inventory(defines.inventory.character_armor)
	local item = inventoryArmor[1]
	if item and item.valid_for_read and item.name:find("ic2%-reactor%-core") then
		player.create_local_flying_text {
			text = item.name .. " is not a armor",
			position = player.position,
			color = {1, 1, 1},
			time_to_live = 80,
			forces = {player.force},
			create_at_cursor = false
		}
		player.get_main_inventory().insert(item)
		inventoryArmor.clear()
	end
end)


script.on_event(events.on_player_joined_game,
	---@param event on_player_joined_game
	function (event)
	game.players[event.player_index]
	game.players[event.player_index].force.research_all_technologies()
	local p = game.players[1].cheat_mode
end)