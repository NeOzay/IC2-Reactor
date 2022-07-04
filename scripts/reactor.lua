local reactor_core = require "scripts.reactor_core"

local Text_rendering = require("scripts.text_rendering")

---@param x number
local function colorMix(x)
	local green = math.max(1 - (x * (1 - 0.498) * 2), 0)
	local red = math.max(math.min(5 * math.pow(x, 2) + x - 0.75, 1), 0)
	return {red, green, 0, 1}
end

local unite = {" W", " kW", " MW", " GW", " TW"}

local function convertion(valeur)
	if valeur ~= 0 then
		local vlog = math.floor(math.log(valeur, 10) / 3)
		valeur = valeur * 10 ^ (-3 * vlog)
		local aron = math.floor(math.log(valeur, 10)) + 1
		return string.format("%0." .. tostring(4 - aron) .. "f", valeur) .. unite[vlog + 1]
	else
		return "0 W"
	end
end

---@class IC2Reactor
---@field inventory LuaEntity
---@field reactorMain LuaEntity
---@field interface LuaEntity
---@field item LuaItemStack
---@field texts table<string, Text_rendering>
---@field status string
---@field is_setup boolean
---@field has_redstone_signal boolean
---@field type string
local reactor = {}
reactor.__index = reactor

---@param entity LuaEntity
function reactor.getIC2Reactor(entity)
	return global.reactorList[entity.unit_number]
end

---@param reactorMainEntity LuaEntity
---@return IC2Reactor
function reactor.new(reactorMainEntity)
	---@type IC2Reactor
	local r = {
		reactorMain = reactorMainEntity,
		status = "idle",
		is_setup = false,
		has_redstone_signal = false,
		type = reactorMainEntity.name
	}

	global.reactorList[reactorMainEntity.unit_number] = r
	return setmetatable(r, reactor)
end

function reactor:setup()
	if not self.is_setup then
		local reactorMain = self.reactorMain
		local surface = reactorMain.surface
		local p, f = reactorMain.position, reactorMain.force

		local inventory = surface.create_entity {name = "ic2-reactor-container", position = p, force = f}
		inventory.destructible = false
		self.inventory = inventory

		local interface = surface.create_entity {
			name = "ic2-reactor-interface",
			position = {x = p.x, y = p.y + 1.5},
			force = f
		}
		interface.destructible = false
		interface.get_or_create_control_behavior()
		interface.operable = false
		self.interface = interface

		local texts = {}
		texts.temp = Text_rendering.new("TEMP:     %", reactorMain, {-0.65, 1.5}, {1, 1, 1, 1})
		texts.heat = Text_rendering.new("00", reactorMain, {0.5, 1.5}, {0, 1, 0, 1})
		texts.power = Text_rendering.new("0 W", reactorMain, {-0.65, 1}, {0, 0, 1, 1})
		self.texts = texts

		self.is_setup = true
		return self
	end
end

function reactor:get_reactor_core()
	local item = self.inventory.get_inventory(defines.inventory.chest)[1]
	if item and item.valid_for_read and item.name:find("ic2%-reactor%-core") then
		self.item = item
		return getIC2ReactorCore(item)
	else
		self.item = nil
	end
end

function reactor:display(core)
	local core_heat_string = string.format("%02d", math.floor((core:get_heat_percent() * 100) + 0.5))
	local core_power_string
	if self.has_redstone_signal then
		core_power_string = convertion(core.layout.energy)
	else
		core_power_string = "0 w"
	end

	local texts = self.texts

	if texts.power.current_text ~= core_power_string then
		trace("update text power")
		texts.power:change_text(core_power_string)

	end
	if texts.heat.current_text ~= core_heat_string then
		trace("update text heat")
		texts.heat:change_color(colorMix(core:get_heat_percent()))
		texts.heat:change_text(core_heat_string)
	end
end

function reactor:remove(player_index)
	local inventory = self.inventory
	local item = inventory.get_inventory(defines.inventory.chest)[1]
	if item then
		if player_index then
			local player = game.get_player(player_index)
			if player.can_insert(item) then
				player.insert(item)
			end
		else
			local core = reactor_core.getIC2ReactorCore(item)
			if core then
				core:remove()
			end
		end
	end
	inventory.destroy()
	self.interface.destroy()
	global.reactorList[self.reactorMain.unit_number] = nil
end

function reactor:on_tick()
	local core = self:get_reactor_core()

	if core then
		local control = self.interface.get_or_create_control_behavior()
		
		if control then
			local red_net = control.get_circuit_network(defines.wire_type.red)
			local green_net = control.get_circuit_network(defines.wire_type.green)

			local signal
			if red_net then
				signal = red_net.get_signal(signals_ID.redstone)
			elseif green_net then
				signal = green_net.get_signal(signals_ID.redstone)
			end

			if signal and signal > 0 then
				self.has_redstone_signal = true
			else
				self.has_redstone_signal = false
			end
		else
			self.has_redstone_signal = false
		end

		if self.status == "idle" then
			core:update(self.item)
			self.status = "running"
		end
		core:on_tick(self)
		self:display(core)
		if core.layout.has_rod and self.has_redstone_signal then
			self.reactorMain.surface.play_sound {
				path = "Geiger",
				position = self.reactorMain.position,
				volume_modifier = 0.8
			}
			self.reactorMain.energy = self.reactorMain.energy + core.energy
		end

	else
		if self.status == "running" then
			self.status = "idle"
			self.texts.power:change_text("0 W")
			self.texts.heat:change_color({0, 1, 0})
			self.texts.heat:change_text("00")
		end
	end
end

return reactor
-- local reactor_core = reactor.inventory.get_inventory(defines.inventory.chest)[1]
