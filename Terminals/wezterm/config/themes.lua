---@module 'config.themes'
---@brief UI themes

require("@types.types")

---@param Config WezTermConfig
---@return nil
return function(Config)
  local wezterm = require("wezterm")

  -- Plattformunabhängiger Pfad
  local home = os.getenv("USERPROFILE") or os.getenv("HOME")
  local prefix = wezterm.target_triple:find("windows") and (home or "E:") or home

  ---@type HackTheBoxColorScheme
  local hackthebox_theme = dofile(prefix .. "/Config/wezterm/color_schemes/hackthebox.lua")

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
end

