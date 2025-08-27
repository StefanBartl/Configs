---@module 'config.keybindings'
---@brief Key mappings for WezTerm, including dynamic color scheme switching
---@version 1.0

local wezterm = require("wezterm")

--@param Config WezTermConfig
--@return nil
return function(Config)
  --- Define custom keybindings
  Config.keys = {
    {
      key = "Enter",
      mods = "ALT",
      action = wezterm.action.DisableDefaultAssignment,
    },

    -- Scroll up 1 line
    { key = "UpArrow", mods = "CTRL", action = wezterm.action.ScrollByLine(-1) },

    -- Scroll down 1 line
    { key = "DownArrow", mods = "CTRL", action = wezterm.action.ScrollByLine(1) },

    -- Scroll up 1 page
    { key = "PageUp", mods = "CTRL", action = wezterm.action.ScrollByPage(-1) },

    -- Scroll down 1 page
    { key = "PageDown", mods = "CTRL", action = wezterm.action.ScrollByPage(1) },

    -- Scroll to top/bottom
    { key = "Home", mods = "CTRL", action = wezterm.action.ScrollToTop },
    { key = "End", mods = "CTRL", action = wezterm.action.ScrollToBottom },


     -- Toggle between color schemes
    {
      key = "1",
      mods = "CTRL|ALT",
      action = wezterm.action.EmitEvent("set-color-hackthebox"),
    },

    -- STRG + SHIFT + Pfeil links → vorheriger Tab
    {
      key = "LeftArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTabRelative(-1),
    },
    -- STRG + SHIFT + Pfeil rechts → nächster Tab
    {
      key = "RightArrow",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTabRelative(1),
    },

    {
      key = "1",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(0),
    },
    {
      key = "2",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(1),
    },
    {
      key = "4",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(2),
    },
    {
      key = "5",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(2),
    },
    {
      key = "6",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(2),
    },
    {
      key = "7",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(2),
    },
    {
      key = "8",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(2),
    },
    {
      key = "9",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ActivateTab(2),
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

    {
      key = "F5",
      mods = "CTRL",
      action = wezterm.action.EmitEvent("set-color-hackthebox"),
   },
   {
      key = "L",
      mods = "CTRL|SHIFT",
      action = wezterm.action.ClearScrollback("ScrollbackAndViewport"),
    },
    {
      key = 'R',
      mods = 'CTRL',
      action = wezterm.action.ShowDebugOverlay
    },

  }
end
