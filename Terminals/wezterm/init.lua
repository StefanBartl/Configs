---@module 'wezterm.repo.init'
--- Repository entry point configuration for WezTerm.
--- This module is executed by the local wezterm.lua via dofile(...) and MUST return a function
--- that takes a Config table and returns the final Config table.

---@param Config table  -- mutable wezterm config table
---@return table        -- finalized config table
return function(Config)
  local wezterm = require("wezterm")
  local is_windows = (wezterm.target_triple or ""):find("windows", 1, true) ~= nil

  -- Submodules live in the same repo dir; package.path is prepared by the entry loader.
  -- Each returns a function(Config) -> nil.
  require("config.features")(Config)
  require("config.fonts")(Config)
  require("config.open_uri")(Config)
  require("config.wsl")(Config)
  -- require("config.tabtitle")(Config)
  require("config.experimental")(Config)
  require("config.appearance")(Config)
	require("config.window_events")(Config)
	require("config.keybindings")(Config)

Config.debug_key_events = true

  if is_windows then
    -- Prefer PowerShell Core when present
    Config.default_prog = { "pwsh.exe", "-NoLogo" }
  end

  Config.window_close_confirmation = "NeverPrompt"

  return Config
end
