---@module 'wezterm'
---@brief OS Entry point configuration for WezTerm
---@version 1.0

local wezterm = require('wezterm')
local Config = wezterm.config_builder()

local sep = package.config:sub(1, 1)
local home ="E:"
local config_root = home .. sep .. "repos" .. sep .. "Configs" .. sep .. "Terminals" .. sep .. "wezterm"

package.path = package.path
  .. ";" .. config_root .. "/?.lua"
  .. ";" .. config_root .. "/?/init.lua"

local myinit = dofile(config_root .. sep .. "myinit.lua")
myinit(Config)

return Config

