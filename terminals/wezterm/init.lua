---@module 'wezterm.repo.init'
--- Repository entry point configuration for WezTerm.
--- This module is executed by the local wezterm.lua via dofile(...) and MUST return a function
--- that takes a Config table and returns the final Config table.

---@param Config table  -- mutable wezterm config table
---@return table        -- finalized config table
return function(Config)
	-- Submodules live in the same repo dir; package.path is prepared by the entry loader.
	-- Each returns a function(Config) -> nil.
	require("config.appearance")(Config)
	require("config.features")(Config)
	require("config.fonts")(Config)
	require("config.open_uri")(Config)
	require("config.powershell")(Config)
	require("config.wsl")(Config)
	require("config.tabtitle")(Config)
	require("config.experimental")(Config)
	require("config.window_events")(Config)
	require("config.keybindings")(Config)
	require("config.terminal_safety")(Config)

	Config.debug_key_events = false
	Config.window_close_confirmation = "NeverPrompt"
	return Config
end
