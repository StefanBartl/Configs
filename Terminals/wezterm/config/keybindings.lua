---@module 'config.keybindings'
---@brief Key mappings for WezTerm, including dynamic color scheme switching

local wezterm = require("wezterm")
local act = wezterm.action

-- local function bind(keys, key, mods, dir)
-- 	keys[#keys + 1] = { key = key, mods = mods, action = act.ActivatePaneDirection(dir) }
-- end

--@param Config WezTerm.Config
--@return nil
return function(Config)
	--- Define custom keybindings
	Config.keys = {

		-- Sendet Shift + Enter an Terminals (nvim) weiter
		{
			key = "Enter",
			mods = "SHIFT",
			action = wezterm.action.SendString("\x1b[13;2u"), -- CSI u: S-Enter
		},

		{
			key = "R",
			mods = "CTRL",
			action = wezterm.action.ShowDebugOverlay,
		},

		-- Sicherstellen, dass die Default-Aktion für CTRL+SHIFT+N nicht greift (wird neu gesetzt mit custom width & heigt)
		{
			key = "n",
			mods = "CTRL|SHIFT",
			action = act.DisableDefaultAssignment,
		},

		{
			key = "Tab",
			mods = "CTRL",
			action = act.DisableDefaultAssignment,
		},

		-- WezTerm's builtin default binds plain CTRL+V to PasteFrom('Clipboard'),
		-- which swallows the keystroke before it ever reaches the terminal app.
		-- Neovim's own <C-v> (Visual Block mode) never sees it as a result.
		-- act.DisableDefaultAssignment does NOT clear this specific builtin (it
		-- still shows up in `wezterm show-keys --lua` afterwards, unlike e.g. the
		-- CTRL+Tab disable above) -- so force the raw keystroke through instead
		-- of asking wezterm to "not do the default". Paste stays available via
		-- the explicit CTRL+SHIFT+V binding below (config/terminal_safety.lua).
		{
			key = "V",
			mods = "CTRL",
			action = act.SendKey({ key = "V", mods = "CTRL" }),
		},

		-- Unser Mapping: Event auslösen -> Handler spawnt und platziert Fenster
		{
			key = "n",
			mods = "CTRL|SHIFT",
			action = act.EmitEvent("spawn_sized_window"),
		},

		{
			key = "LeftArrow",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivateTabRelative(-1),
		},
		-- STRG + SHIFT + Pfeil rechts → nächster Tab
		{
			key = "RightArrow",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivateTabRelative(1),
		},

		{
			key = "w",
			mods = "CTRL|SHIFT|ALT",
			action = wezterm.action.CloseCurrentPane({ confirm = true }),
		},
		{
			key = "L",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ShowLauncher,
		},
	}

	-- Workaround (windows)
	-- bind(Config.keys, "k", "CTRL|SHIFT|ALT", "Up")
	-- bind(Config.keys, "h", "CTRL|SHIFT|ALT", "Left")
	-- bind(Config.keys, "j", "CTRL|SHIFT|ALT", "Down")
	-- bind(Config.keys, "l", "CTRL|SHIFT|ALT", "Right")
end
