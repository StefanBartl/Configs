---@module 'config.window_events'
--- Registers gui-startup and a custom "spawn_sized_window" event, so both the
--- first window and CTRL+SHIFT+N created windows use the same placement logic.

local wezterm = require("wezterm")
local placement = require("utils.window_placement")

---@return nil
return function(_)
  local defaults = {
    width_factor = 0.90,
    height_factor = 0.80,
    center = true,
    origin = "ActiveScreen",
  }

  wezterm.on("gui-startup", function(cmd)
    local mux = wezterm.mux
    local screens = wezterm.gui.screens()
    local s = screens.active
    local _, _, mw = mux.spawn_window(cmd or {})
    local win = mw:gui_window()
    placement.apply_to_window(win, s, defaults)
  end)

  wezterm.on("spawn_sized_window", function(_, _)
    placement.spawn_sized_window(defaults)
  end)
end

