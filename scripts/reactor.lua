local Layout = require "scripts.layout"

local Text_rendering = require("scripts.text_rendering")

---@param x number
local function colorMix(x)
	local green = math.max(1 - (x * (1 - 0.498) * 2), 0)
	local red = math.max(math.min(5 * math.pow(x, 2) + x - 0.75, 1), 0)
	return { red, green, 0, 1 }
end

local unite = { " W", " kW", " MW", " GW", " TW" }

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
---@field reactorMain LuaEntity
---@field interface LuaEntity
---@field texts table<string, Text_rendering>
---@field status "idle"|"running"
---@field is_setup boolean
---@field has_redstone_signal boolean
---@field guis table<integer,Gui>
---@field layout IC2Layout
---@field type string
---@field internal_heat number
---@field max_internal_heat number
---@field health number
---@field id integer
local IC2Reactor = {}
IC2Reactor.__index = IC2Reactor

---@param entity LuaEntity
function IC2Reactor.getIC2Reactor(entity)
	return global.reactors[entity.unit_number]
end

---@param reactorMainEntity LuaEntity
---@return IC2Reactor
function IC2Reactor.new(reactorMainEntity)
	local reactor = setmetatable({
		reactorMain = reactorMainEntity,
		status = "idle",
		is_setup = false,
		has_redstone_signal = false,
		type = reactorMainEntity.name,
		owner = reactorMainEntity,
		id = reactorMainEntity.unit_number,
		max_internal_heat = REACTOR_CONST.maxhealth,
		internal_heat = 0
	}, IC2Reactor)
	reactor.layout = Layout.new(reactor, REACTOR_GRID.w, REACTOR_GRID.h)
	global.reactors[reactorMainEntity.unit_number] = reactor
	global.class_instances.IC2Reactor[reactor] = true
	return reactor
end

function IC2Reactor.restore(object)
	setmetatable(object, IC2Reactor)
	for _, text in pairs(object.texts) do
		setmetatable(text, Text_rendering)
	end
end

---@return boolean, IC2Reactor? success
function IC2Reactor:setup()
	if self.is_setup then
		return true
	end
	local reactorMain = self.reactorMain
	local surface = reactorMain.surface
	local p, f = reactorMain.position, reactorMain.force

	local interface = surface.create_entity {
		name = "ic2-reactor-interface",
		position = { x = p.x, y = p.y + 1.5 },
		force = f
	}
	if not interface then
		return false
	end

	interface.destructible = false
	interface.get_or_create_control_behavior()
	interface.operable = false
	self.interface = interface

	local texts = {}
	texts.temp = Text_rendering.new("TEMP:     %", reactorMain, { -0.65, 1.5 }, { 1, 1, 1, 1 })
	texts.heat = Text_rendering.new("00", reactorMain, { 0.5, 1.5 }, { 0, 1, 0, 1 })
	texts.power = Text_rendering.new("0 W", reactorMain, { -0.65, 1 }, { 0, 0, 1, 1 })
	self.texts = texts

	self.is_setup = true
	return true, self
end

function IC2Reactor:display(core)
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

function IC2Reactor:remove(player_index)
	self.interface.destroy()
	global.reactors[self.reactorMain.unit_number] = nil
end

function IC2Reactor:on_tick()

	local control = self.interface.get_or_create_control_behavior()

	if control then
		local red_net = control.get_circuit_network(defines.wire_type.red)
		local green_net = control.get_circuit_network(defines.wire_type.green)

		local signal
		if red_net then
			signal = red_net.get_signal(SIGNALS_ID.redstone)
		elseif green_net then
			signal = green_net.get_signal(SIGNALS_ID.redstone)
		end

		if signal and signal > 0 then
			self.has_redstone_signal = true
		else
			self.has_redstone_signal = false
		end
	else
		self.has_redstone_signal = false
	end

	local energy_product = self.layout:on_tick()
	--self:display(core)
	if self.layout.rod_count and self.has_redstone_signal then
		self.reactorMain.surface.play_sound {
			path = "Geiger",
			position = self.reactorMain.position,
			volume_modifier = 0.8
		}
	end
	self.reactorMain.energy = self.reactorMain.energy + energy_product
end

function IC2Reactor:calc_health()
	self.health = math.min((self.max_internal_heat - self.internal_heat) / self.max_internal_heat, 0)
end

---@param heat number
function IC2Reactor:set_heat(heat)
	self.heat = math.max(heat, 0)
	self:calc_health()
	return self.heat
end

function IC2Reactor:add_heat(heat)
	local old_heat = self.internal_heat
	self.internal_heat = math.max(self.internal_heat + heat, 0)
	self:calc_health()
	return self.internal_heat - old_heat
end

---@param truc IC2Component|IC2Reactor
---@param heat number
function IC2Reactor:transfer_to(truc, heat)
	local pull_heat = self:add_heat(-heat)
	truc:add_heat(math.abs(pull_heat))
end

function IC2Reactor:open_gui(player)

end

return IC2Reactor
