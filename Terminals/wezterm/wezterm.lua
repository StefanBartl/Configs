---@module 'wezterm'
---@brief Entry point configuration for WezTerm
---@version 1.0

local wezterm = require('wezterm')
local Config = wezterm.config_builder()

require('config.appearance')(Config)
require('config.fonts')(Config)
require('config.keybindings')(Config)
require('config.open_uri')(Config)
require('config.wsl')(Config)

Config.default_prog = { "pwsh.exe", "-NoLogo" }
--Config.default_prog = { '/usr/bin/zsh', '-l' }
Config.window_close_confirmation = "NeverPrompt"


return Config
