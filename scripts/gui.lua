---@class Gui
---@field main_frame LuaGuiElement
---@field reactor_interior_frame LuaGuiElement
---@field slot_list LuaGuiElement[]
---@field player LuaPlayer
---@field layout Layout
---@field reactor IC2Reactor
local Gui = {}
Gui.__index = Gui

---@param gui Gui
local function build_reactor_grid(gui)
  local reactor_interior_frame = gui.reactor_interior_frame
  reactor_interior_frame.clear()
  local layout_frame = reactor_interior_frame.add { type = "frame", name = "layout_frame" }
  local flow = layout_frame.add { type = "flow", direction = "vertical" }

  for y = 1, gui.layout.height do
    local button_table = flow.add { type = "table", column_count = REACTOR_GRID.w, style = "filter_slot_table" }
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

---@param player LuaPlayer
---@param reactor IC2Reactor
function Gui.new(player, reactor)
  local gui = setmetatable({
    player = player,
    reactor = reactor,
    layout = reactor.layout
  }, Gui)
  local screen_element = player.gui.screen
  local main_frame = screen_element.add { type = "frame", name = "IC2_main_frame", caption = "Reactor", style =
  "IC2_content_frame" }
  main_frame.auto_center = true

  gui.main_frame = main_frame

  --main_frame.style.size = { 800, 500 }
  --player.opened = main_frame

  local body = main_frame.add { type = "flow", direction = "vertical" }
  local reactor_interior_frame = body.add { type = "frame", name = "Reactor_interior_frame", direction = "vertical", style =
  "IC2_interior_frame" }
  local info = body.add { type = "frame", direction = "horizontal" }
  info.add { type = "label", caption = "power output" }
  info.add { type = "progressbar", style = "IC2_heat_bar" }
  build_reactor_grid(gui)
  return gui
end

function Gui:toggle()
  local main_frame = self.main_frame
  main_frame.visible = not main_frame.visible
end

function Gui:get_slot(x, y)
  return self.slot_list[x + (y - 1) * self.layout.width]
end

function Gui:update_slot(x, y)
  local slot = self:get_slot(x, y)
  local component = self.layout:get_component(x, y)
  if not component then
    self:clear_slot(x, y)
    return
  end

  if component.health == 1 then
    slot.bar.visible = false
  else
    slot.bar.visible = true
    slot.bar.value = component.health
  end
end

function Gui:clear_slot(x, y)
  local slot = self:get_slot(x, y)
  slot.bar.visible = false
  slot.IC2_button_slot.sprite = nil
end
