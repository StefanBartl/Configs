---@module 'wezterm'
---@brief Repository entry point configuration for WezTerm
---@version 1.0

---@param Config table
---@return table
return function(Config)
  require('config.appearance')(Config)
  require('config.features')(Config)
  require('config.fonts')(Config)
  require('config.keybindings')(Config)
  require('config.open_uri')(Config)
  require('config.themes')(Config)
  require('config.wsl')(Config)

  Config.default_prog = { "pwsh.exe", "-NoLogo" }
  Config.window_close_confirmation = "NeverPrompt"

  return Config
end
