---@module 'wezterm'
---@brief Repository entry point configuration for WezTerm
---@version 1.0

---@param Config table
---@return table
return function(Config)
  local wezterm = require("wezterm")
  local is_windows = wezterm.target_triple:find("windows")

  require('config.appearance')(Config)
  require('config.features')(Config)
  require('config.fonts')(Config)
  require('config.keybindings')(Config)
  require('config.open_uri')(Config)


  require('config.wsl')(Config)

Config.color_scheme = 'Homebrew'

  if is_windows then
   Config.default_prog = { 'pwsh.exe', '-NoLogo'}
  end

  Config.window_close_confirmation = "NeverPrompt"

  return Config
end

