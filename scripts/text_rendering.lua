---@class Text_rendering
---@field current_text LocalisedString
---@field id uint64
local Text_rendering = {}
Text_rendering.__index = Text_rendering

---@param text LocalisedString
---@param target Position|LuaEntity
---@param target_offset Vector
---@param color Color
function Text_rendering.new(text, target, target_offset, color)
	local surface = target.surface or game.surfaces[1]
	local id = rendering.draw_text{
		text = text,
		surface = surface,
		target = target,
		color = color,
		target_offset = target_offset
	}
	---@type Text_rendering
	local tr = {
		id=id,
		current_text = text
	}
	return setmetatable(tr, Text_rendering)
end

---@param text string
function Text_rendering:change_text(text)
	rendering.set_text(self.id, text)
	self.current_text = text
end

---@param target Position|LuaEntity
---@param target_offset Vector
function Text_rendering:change_target(target, target_offset)
	rendering.set_target(self.id, target, target_offset)
end

---@param color Color
function Text_rendering:change_color(color)
	rendering.set_color(self.id, color)
end

function Text_rendering:remove()
	rendering.destroy(self.id)
end

return Text_rendering