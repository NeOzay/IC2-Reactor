local reactor_core = require "scripts.reactor_core"

local Text_rendering = require("scripts.text_rendering")

---@class IC2FluidReactor:IC2Reactor
---@field inventory LuaEntity
---@field reactorMain LuaEntity
---@field interface LuaEntity
---@field item LuaItemStack
---@field texts table<string, Text_rendering>
---@field status string
---@field is_setup boolean
---@field has_redstone_signal boolean
local fluid_reactor = {}
fluid_reactor.__index = fluid_reactor

---@param reactorMainEntity LuaEntity
---@return IC2FluidReactor
function fluid_reactor.new(reactorMainEntity)
	---@type IC2Reactor
	local r = {
		reactorMain = reactorMainEntity,
		status = "idle",
		is_setup = false,
		has_redstone_signal = false,
		type = reactorMainEntity.name
	}
	global.reactors[reactorMainEntity.unit_number] = r
	return setmetatable(r, fluid_reactor)
end

function fluid_reactor:setup()
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
		interface.operable = false
		self.interface = interface

		--[[ local texts = {}
		texts.temp = Text_rendering.new("TEMP:     %", reactorMain, {-0.65, 1.5}, {1, 1, 1, 1})
		texts.heat = Text_rendering.new("00", reactorMain, {0.5, 1.5}, {0, 1, 0, 1})
		texts.power = Text_rendering.new("0 W", reactorMain, {-0.65, 1}, {0, 0, 1, 1})
		self.texts = texts ]]

		local tank_input = surface.create_entity {
			name = "ic2-fluid-reactor-input",
			position = {x = p.x-1.5, y = p.y + 1.5},
			force = f
		}
		local tank_output = surface.create_entity {
			name = "ic2-fluid-reactor-output",
			position = {x = p.x+1.5, y = p.y + 1.5},
			force = f
		}

		self.is_setup = true
		return self
	end
end

return fluid_reactor
