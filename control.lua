require("util")
require("scripts.const")
local Reactor = require("scripts.reactor")
local Fluid_reactor = require("scripts.fluid_reactor")
local Layout = require("scripts.layout")
local Gui = require("scripts.gui")
local Component = require("scripts.components")
local Text_rendering = require "scripts.text_rendering"

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
	Reactor.getIC2Reactor(event.entity.unit_number):remove(event.player_index)
end

local function init()
	local function weak_table() return setmetatable({}, { __mode = "k" }) end
	global.reactors = global.reactors or {} ---@type IC2Reactor[]
	global.class_instances = global.class_instances or {}
	local class_instances = global.class_instances
	global.class_instances.IC2Reactor = class_instances.IC2Reactor or weak_table()
	global.class_instances.IC2Component = class_instances.IC2Component or weak_table()
	global.class_instances.IC2Layout = class_instances.IC2Layout or weak_table()
	global.class_instances.IC2Gui = class_instances.IC2Gui or weak_table()
end

local function load()
	-- logging(serpent.block(global.reactorList) or "test")
	Reactor.restore()
	Layout.restore()
	Component.restore()
	Gui.restore()
end

---@param ticks NthTickEventData
local function ontick(ticks)
	for _, reactor in pairs(global.reactors) do
		reactor:on_tick()
		for _, gui in pairs(reactor.guis) do
			gui:update()
		end
	end
end


script.on_init(init)
script.on_configuration_changed(init)
script.on_load(load)

script.on_nth_tick(60, ontick)



local events = defines.events
script.on_event(events.on_built_entity, buildReactor,
	{ { filter = "name", name = "ic2-reactor-main", mode = "or" }, { filter = "name", name = "ic2-fluid-reactor-main" } })
script.on_event(events.on_pre_player_mined_item, removeReactor, { { filter = "name", name = "ic2-reactor-main" } })
script.on_event(events.on_entity_died, removeReactor, { { filter = "name", name = "ic2-reactor-main" } })


script.on_event(events.on_player_joined_game, function(event)
	game.players[event.player_index].cheat_mode = true
	game.players[event.player_index].force.research_all_technologies()
end)
script.on_event(events.on_player_left_game, function(event)
	for key, reactor in pairs(global.reactors) do
		reactor:destroy_gui(event.player_index)
	end
end)


script.on_event(defines.events.on_gui_opened, function (event)
	if not event.entity or event.entity.name ~= "ic2-reactor-main" then return end
	local player = game.get_player(event.player_index)
	local entity = event.entity
	local reactor = Reactor.getIC2Reactor(entity.unit_number)
	if not (reactor and player) then return end
	local frame, visible = reactor:toggle_gui(player)
	if visible then
		player.opened = frame
	else
		player.opened = nil
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
	if not (event.element and event.element.name:find("^IC2")) then return end
	local player = game.get_player(event.player_index)
	local element = event.element
	local reactor = Reactor.getIC2Reactor(element.tags.reactor_id --[[@as number]])
	if not player or not reactor then return end

	local gui = reactor.guis[event.player_index]
	if element.name == "IC2_button_slot" then
		local cursor_item_name
		local cursor_stack = player.cursor_stack
		local x, y = element.tags.x, element.tags.y ---@type number,number

		if cursor_stack.valid_for_read then ---@cast cursor_stack -?
			cursor_item_name = player.cursor_stack.name
			local current_sprite = element.sprite
			local cursor_sprite = "item/"..player.cursor_stack.name
			if current_sprite == "" then
				local success = reactor.layout:insert_component(cursor_stack, x, y)
				if success then cursor_stack.count = cursor_stack.count - 1 end
				gui:update_slot_at(x, y)
			elseif cursor_sprite == current_sprite then
				local component = reactor.layout:get_component(x, y)
				if component.health ~= 1 then return end
				local success = reactor.layout:remove_component_at(x, y)
				if success then cursor_stack.count = cursor_stack.count + 1 end
				gui:update_slot_at(x, y)
			elseif cursor_stack.count == 1 then
				local removed = reactor.layout:remove_component_at(x, y)
				if removed then
					local success = reactor.layout:insert_component(cursor_stack, x, y)
					if success then
						cursor_stack.count = cursor_stack.count - 1
						cursor_stack.set_stack({ name = removed.name, count = 1, health = removed.health })
					end
				end
				gui:update_slot_at(x, y)
			end
		else
			local removed = reactor.layout:remove_component_at(x, y)
			if removed then
				cursor_stack.set_stack({ name = removed.name, count = 1, health = removed.health })
			end
			gui:update_slot_at(x, y)
		end
	end

	if element.name == "IC2_close_button" then
		gui:hide()
	end
end)
