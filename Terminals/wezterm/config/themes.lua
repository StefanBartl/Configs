---@module 'config.themes'
---@brief UI themes

require("@types.types")

---@param Config WezTermConfig
---@return nil
return function(Config)
  local wezterm = require("wezterm")

  -- Neapsix's Rose Pine via plugin
  --local theme = wezterm.plugin.require('https://github.com/neapsix/wezterm').main
  --Config.colors = theme.colors()
  --Config.window_frame = theme.window_frame() -- required for fancy tab bar look


  -- Activate Hack the Box theme

  ---@type HackTheBoxColorScheme
  local hackthebox_theme = dofile("E:/MyGithub/Configs/Terminals/wezterm/color_schemes/hackthebox.lua")

  local palette = {}
  for k, v in pairs(hackthebox_theme) do
    if k ~= "name" then
      palette[k] = v
    end
  end

  Config.color_schemes = {
    [hackthebox_theme.name] = palette,
  }

  Config.color_scheme = hackthebox_theme.name

  wezterm.on("set-color-hackthebox", function(window, _)
    window:set_config_overrides({
      color_scheme = hackthebox_theme.name,
    })
  end)

  -- Alternative fallback to built-in theme
  -- Config.color_scheme = 'rose-pine'
end
