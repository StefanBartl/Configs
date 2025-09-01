---@module 'wezterm.tabline_wez_integration'
--- Integrates michaelbrusegard/tabline.wez using a function(Config) wrapper.
--- Calls tabline.setup() FIRST (to initialize theme), then apply_to_config().
--- Works cross-platform; requires a Nerd Font for powerline separators/icons.

local wezterm = require("wezterm")

---@return nil
return function(Config)
	-- 1) Load plugin
	local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	-- 2) Choose theme SOURCE for tabline:
	--    Prefer an explicit colors object, else a configured scheme name,
	--    else fall back to a safe builtin.
	--    tabline.wez accepts either a string (scheme name) OR a WezTerm colors table.
	local theme_source = Config.colors or Config.color_scheme or "Catppuccin Mocha"

	-- 3) Setup FIRST: initializes internal theme and component graph.
	--    If Nerd Font glyphs are not desired/available, set separators to ''.
	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "Tokyo Night",
			tabs_enabled = true,
			section_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
			component_separators = {
				left = wezterm.nerdfonts.pl_left_soft_divider,
				right = wezterm.nerdfonts.pl_right_soft_divider,
			},
			tab_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
			theme_overrides = {}, -- optional overrides per mode/keytable
		},
		sections = {
			tabline_a = { " WKD" },
			tabline_b = {},
			tabline_c = {},

			tab_active = {
			},
			tab_inactive = {
			},
			tabline_x = {},
			tabline_y = {},
			tabline_z = {},
		},
		extensions = {},
	})

	tabline.apply_to_config(Config)
	Config.tab_bar_at_bottom = true
	Config.use_fancy_tab_bar = false
	Config.hide_tab_bar_if_only_one_tab = false
	Config.show_new_tab_button_in_tab_bar = false
	Config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
	Config.window_padding = { left = 9, right = 8, top = 8, bottom = 8 }
end
