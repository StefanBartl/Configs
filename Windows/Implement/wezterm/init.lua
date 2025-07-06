
local wezterm = require("wezterm")

-- Base drive
local drive = "E:" -- My Windows PC
local configdir = drive .. "/MyGithub/Configs/Terminal/wezterm"

-- Lade zusätzliche Konfigdatei
dofile(configdir .. "/my_theme.lua")
