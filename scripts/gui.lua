---@class IC2Gui
---@field main_frame LuaGuiElement
---@field reactor_interior_frame LuaGuiElement
---@field reactor_heat_bar LuaGuiElement
---@field reactor_output LuaGuiElement
---@field title LuaGuiElement
---@field slot_list LuaGuiElement[]
---@field player LuaPlayer
---@field layout IC2Layout
---@field reactor IC2Reactor
local Gui = {}
Gui.__index = Gui

function Gui.restore()
  for instance in pairs(global.class_instances.IC2Gui) do
    setmetatable(instance, Gui)
  end
end

---@param gui IC2Gui
local function build_reactor_grid(gui)
  local reactor_interior_frame = gui.reactor_interior_frame
  reactor_interior_frame.clear()
  local layout_frame = reactor_interior_frame.add { type = "frame", name = "layout_frame" }
  local flow = layout_frame.add { type = "flow", direction = "vertical" }

  for y = 1, gui.layout.height do
    local button_table = flow.add { type = "table", column_count = gui.layout.width, style = "filter_slot_table" }
    for x = 1, gui.layout.width do
      local slot = button_table.add { type = "flow", direction = "vertical", style = "IC2_reactor_slot_flow" }
      local button = slot.add { type = "sprite-button", tags = { x = x, y = y, reactor_id = gui.reactor.id }, style = "inventory_slot", name =
      "IC2_button_slot" }
      button.style.size = { 60, 60 }
      local progressbar = slot.add { type = "progressbar", value = 0.5, style = "IC2_component_bar", name = "bar" }
      progressbar.style.size = { 54, 5 }
      progressbar.visible = false
      table.insert(gui.slot_list, slot)
    end
  end
end

---@param gui IC2Gui
local function build_title(gui)
  local title = gui.title
  title.drag_target = gui.main_frame
  title.add{type = "label", caption = "Reactor", ignored_by_interaction = true, style = "IC2_title_text"}
  title.add{type = "empty-widget", style = "IC2_title_drag", ignored_by_interaction = true }
  local button = title.add{type = "sprite-button", name = "IC2_close_button", style = "frame_action_button", sprite = "utility/close_white", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black"}
  button.tags = {reactor_id = gui.reactor.id}
end

---@param player LuaPlayer
---@param reactor IC2Reactor
function Gui.new(player, reactor)
  local gui = setmetatable({
    player = player,
    reactor = reactor,
    layout = reactor.layout,
    slot_list = {}
  }, Gui)
  local screen_element = player.gui.screen
  local main_frame = screen_element.add { type = "frame", name = "IC2_main_frame "..reactor.id, style =
  "IC2_content_frame", direction = "vertical" }
  main_frame.auto_center = true

  gui.main_frame = main_frame

  --main_frame.style.size = { 800, 500 }
  --player.opened = main_frame
  gui.title = main_frame.add{type = "flow",direction = "horizontal", style = "IC2_titlebar_flow"}
  build_title(gui)
  gui.reactor_interior_frame = main_frame.add { type = "frame", name = "Reactor_interior_frame", direction = "vertical", style = "IC2_interior_frame" }
  local info = main_frame.add { type = "frame", direction = "horizontal" }
  gui.reactor_heat_bar = info.add { type = "progressbar", style = "IC2_heat_bar", name = "reactor_heat_bar" }
  gui.reactor_output = info.add { type = "label", caption = "power output", name = "reactor_output" }
  build_reactor_grid(gui)
  global.class_instances.IC2Gui[gui] = true
  return gui
end

function Gui:toggle()
  self.main_frame.visible = not self.main_frame.visible
  self:update()
  return self.main_frame.visible
end

function Gui:show()
  self.main_frame.visible = true
  self:update()
end

function Gui:hide()
  self.main_frame.visible = false
end

function Gui:get_slot(x, y)
  return self.slot_list[x + (y - 1) * self.layout.width]
end

function Gui:update_slot_at(x, y)
  local slot = self:get_slot(x, y)
  local component = self.layout:get_component(x, y)
  if not component then
    self:clear_slot(slot)
    return
  end

  if component.health == 1 then
    slot.bar.visible = false
  else
    slot.bar.visible = true
    slot.bar.value = component.health
  end
  if slot.IC2_button_slot.sprite ~= "item/"..component.name then
    slot.IC2_button_slot.sprite = "item/"..component.name
  end
  slot.IC2_button_slot.tooltip = "Durability: "..component.max_heat-component.heat.."/"..component.max_heat
end

---@param slot LuaGuiElement
function Gui:update_slot(slot)
  local component = self.layout:get_component(slot.IC2_button_slot.tags.x, slot.IC2_button_slot.tags.y)
  if not component then
    self:clear_slot(slot)
    return
  end

  if component.health == 1 then
    slot.bar.visible = false
  else
    slot.bar.visible = true
    slot.bar.value = component.health
  end
  if slot.IC2_button_slot.sprite ~= "item/"..component.name then
    slot.IC2_button_slot = "item/"..component.name
  end
  if component.name ~= "component-heat-vent" then
    slot.IC2_button_slot.tooltip = "Durability: "..component.max_heat-component.heat.."/"..component.max_heat
  end
end

function Gui:update_all_slot()
  for key, slot in pairs(self.slot_list) do
    self:update_slot(slot)
  end
end
function Gui:update_power()
  self.reactor_output.caption = Convertion(self.reactor.energy)
end

function Gui:update_heat()
  self.reactor_heat_bar.value = 1 - self.reactor.health
end

function Gui:update()
  if not self.main_frame.visible then return end
  self:update_all_slot()
  self:update_power()
  self:update_heat()
end

function Gui:clear_slot_at(x, y)
  local slot = self:get_slot(x, y)
  slot.bar.visible = false
  slot.IC2_button_slot.sprite = nil
end

---@param slot LuaGuiElement
function Gui:clear_slot(slot)
  slot.bar.visible = false
  slot.IC2_button_slot.sprite = nil
end

return Gui
