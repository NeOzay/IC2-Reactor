---@class Gui
---@field main_frame LuaGuiElement
---@field reactor_interior_frame LuaGuiElement
---@field slot_list LuaGuiElement[]
---@field player LuaPlayer
local Gui = {}
Gui.__index = Gui

---@param player LuaPlayer
local function build_reactor_grid(player, reactor_interior_frame)
  game.print(player.index)
  reactor_interior_frame.clear()
  local layout_frame = reactor_interior_frame.add { type = "frame", name = "layout_frame" }
  local flow = layout_frame.add { type = "flow", direction = "vertical" }
  for h = 1, REACTOR_GRID.h do
    local button_table = flow.add { type = "table", column_count = REACTOR_GRID.w, style = "filter_slot_table" }
    for w = 1, REACTOR_GRID.w do
      local slot = button_table.add { type = "flow", direction = "vertical", style = "IC2_reactor_slot_flow" }
      local b = slot.add { type = "sprite-button", tags = { w = w, h = h, item = nil }, style = "inventory_slot", name =
      "IC2_button_slot" }
      b.style.size = { 60, 60 }
      local progressbar = slot.add { type = "progressbar", value = 0.5, style = "IC2_component_bar", name = "bar" }
      progressbar.style.size = { 54, 5 }
      b.tags["bar"] = progressbar
      progressbar.visible = false
    end
  end
end

---@param player LuaPlayer
---@param reactor IC2Reactor
function Gui.new(player, reactor)
  local gui = setmetatable({
    player = player
  }, Gui)
  local screen_element = player.gui.screen
  local main_frame = screen_element.add { type = "frame", name = "IC2_main_frame", caption = "Reactor", style =
  "IC2_content_frame" }
  main_frame.auto_center = true

  gui.main_frame = main_frame

  --main_frame.style.size = { 800, 500 }
  --player.opened = main_frame

  --local info_frame = main_frame.add { type = "frame", name = "Reactor_info_frame", direction = "vertical", style = "IC2_content_frame", caption = "Information" }
  local body = main_frame.add { type = "flow", direction = "vertical" }
  local reactor_interior_frame = body.add { type = "frame", name = "Reactor_interior_frame", direction = "vertical", style =
  "IC2_interior_frame" }
  local info = body.add { type = "frame", direction = "horizontal" }
  info.add { type = "label", caption = "power output" }
  info.add { type = "progressbar", style = "IC2_heat_bar" }
  build_reactor_grid(player, reactor_interior_frame)
  return main_frame
end

local function gui:toggle()
    local player_global = global.players[player.index]
    local main_frame = player_global.elements.main_frame

    if main_frame == nil then
        build_interface(player)
    else
        main_frame.destroy()
        player_global.elements = {}
    end
end
