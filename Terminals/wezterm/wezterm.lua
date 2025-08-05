-- ~/.config/wezterm/wezterm.lua

local wezterm = require("wezterm")

-- Erstelle initiale Konfigurationstabelle
local config = {}

-- Rufe deinen EntryPoint auf und gib das Ergebnis zurück
return require("myinit")(config)
