---@module 'config.fonts'
---@brief Extended font fallback configuration for maximum glyph coverage in WezTerm

require("@types.types")

local wezterm = require("wezterm")
local font_utils = require("utils.font")

---Configure font settings for WezTerm with extensive fallback chain
---@param Config WezTerm.Config The WezTerm configuration table
---@return nil
return function(Config)
	-- Ensure required Nerd Fonts are installed
	font_utils.ensure_jetbrains_font()

	--- Base font size in points
	Config.font_size = 12

	--- Font fallback list ordered by priority
	Config.font = wezterm.font_with_fallback({
		-- Primary programming font (clean text rendering)
		{
			family = "Source Code Pro",
			weight = "Regular",
			harfbuzz_features = {
				-- Character variants
				"cv01", "cv05", "cv08", "cv10", "cv06",
				"cv12", "cv14", "cv16", "cv25", "cv26",
				"cv28", "cv29", "cv31", "cv32",
				-- Stylistic sets
				"ss03", "ss04", "ss05", "ss07", "ss09",
			},
		},

		-- Primary Nerd Font fallback for PUA icons
		{
			family = "JetBrainsMono Nerd Font",
			weight = "Regular",
		},

		-- Symbol-focused Nerd Font (covers additional icon ranges)
		{
			family = "Symbols Nerd Font Mono",
		},

		-- Powerline and legacy glyphs (some prompts still use this)
		{
			family = "PowerlineSymbols",
		},

		-- Emoji support (color emoji)
		{
			family = "Noto Color Emoji",
		},

		-- Box drawing and general Unicode safety net
		{
			family = "DejaVu Sans Mono",
		},
	})
end
