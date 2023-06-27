local Layout = require "scripts.layout"
local Gui = require "scripts.gui"

---@class IC2Reactor
---@field entity LuaEntity
---@field interface LuaEntity
---@field status "idle"|"running"
---@field is_setup boolean
---@field has_redstone_signal boolean
---@field layout IC2Layout
---@field type string
---@field internal_heat number
---@field max_internal_heat number
---@field health number
---@field energy number
---@field id integer
local IC2Reactor = {}
IC2Reactor.__index = IC2Reactor

function IC2Reactor.restore()
	for instance in pairs(global.class_instances.IC2Reactor) do
		setmetatable(instance, IC2Reactor)
	end
end

---@param unit_number number?
---@return IC2Reactor?
function IC2Reactor.getIC2Reactor(unit_number)
	return global.reactors[unit_number]
end

---@param entity LuaEntity
---@return IC2Reactor
function IC2Reactor.new(entity)
	local reactor = setmetatable({
		entity = entity,
		status = "idle",
		is_setup = false,
		has_redstone_signal = false,
		type = entity.name,
		id = entity.unit_number,
		max_internal_heat = REACTOR_CONST.maxhealth,
		internal_heat = 0,
		guis = {},
		energy = 0,
	}, IC2Reactor)
	reactor.layout = Layout.new(reactor, REACTOR_GRID.w, REACTOR_GRID.h)
	reactor:calc_health()
	global.reactors[entity.unit_number] = reactor
	global.class_instances.IC2Reactor[reactor] = true
	return reactor
end

---@return boolean, IC2Reactor? success
function IC2Reactor:setup()
	if self.is_setup then
		return true
	end

	self.is_setup = true
	return true, self
end

function IC2Reactor:remove()
	if self.interface then
		self.interface.destroy()
	end
	global.reactors[self.id] = nil
end

function IC2Reactor:on_tick()

	local control = self.entity.get_or_create_control_behavior()

	local signal = 0
	if control then
		local red_net = control.get_circuit_network(defines.wire_type.red)
		local green_net = control.get_circuit_network(defines.wire_type.green)

		if red_net then
			signal = signal + red_net.get_signal(SIGNALS_ID.redstone)
		end
		if green_net then
			signal = signal + green_net.get_signal(SIGNALS_ID.redstone)
		end
	end
	if signal > 0 then
		self.has_redstone_signal = true
	else
		self.has_redstone_signal = false
	end

	local energy_product = self.layout:on_tick()
	if self.layout.rod_count > 0 and self.has_redstone_signal then
		self.entity.surface.play_sound {
			path = "Geiger",
			position = self.entity.position,
			volume_modifier = 0.8
		}
	end
	self.entity.energy = self.entity.energy + energy_product
	self.energy = energy_product
end

function IC2Reactor:calc_health()
	self.health = math.max((self.max_internal_heat - self.internal_heat) / self.max_internal_heat, 0)
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

return IC2Reactor
