---@module 'config.keybindings'
---@brief Key mappings for WezTerm, including dynamic color scheme switching
---@version 1.0

local wezterm = require("wezterm")

--@param Config WezTermConfig
--@return nil
return function(Config)
  --- Define custom keybindings
  Config.keys = {
    -- Toggle between color schemes
    {
      key = "1",
      mods = "CTRL|ALT",
      action = wezterm.action.EmitEvent("set-color-hackthebox"),
    },

    -- Move between panes
    {
      key = "h",
      mods = "CTRL|ALT",
      action = wezterm.action.ActivatePaneDirection("Left"),
    },
    {
      key = "l",
      mods = "CTRL|ALT",
      action = wezterm.action.ActivatePaneDirection("Right"),
    },
    {
      key = "k",
      mods = "CTRL|ALT",
      action = wezterm.action.ActivatePaneDirection("Up"),
    },
    {
      key = "j",
      mods = "CTRL|ALT",
      action = wezterm.action.ActivatePaneDirection("Down"),
    },
  }
end
