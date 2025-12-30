---@module 'config.fonts'
---@brief Font configuration for WezTerm using fallback and typographic ligatures
require("@types.types")

local wezterm = require("wezterm")
local font_utils = require("utils.font")



---Configure font settings for WezTerm including size, family, and OpenType features
---@param Config WezTerm.Config The WezTerm configuration table
---@return nil
return function(Config)
	-- Ensure JetBrainsMono Nerd Font is available
	font_utils.ensure_jetbrains_font()

	---Base font size in points
	Config.font_size = 12

	---Font fallback list with typographic options
	Config.font = wezterm.font_with_fallback({
		-- Primary programming font
		{
            family = "Source Code Pro",
			-- family = "Inter Mono",
			-- family = "IBM Plex Mono",
			-- family = "JetBrainsMono Nerd Font",
			weight = "Regular",
			harfbuzz_features = {
				-- Character variants for better developer ergonomics:
				"cv01", -- alternate a
				"cv05", -- alternate g
				"cv08", -- i with serif
				"cv10", -- slashed zero
				"ss08", -- distinct equals and colon
				"cv06", -- i: alternate glyph
				"cv12", -- 0: slashed zero
				"cv14", -- 3: alternate 3
				"cv16", -- *: alternate asterisk
				"cv25", -- .-: dotted minus
				"cv26", -- :-: alternate colon-dash
				"cv28", -- {. .}: open/close brace variant
				"cv29", -- { }: normal brace variant
				"cv31", -- (): alternate parentheses
				"cv32", -- .=: dotted equals
				-- Stylistic sets for operators and symbols:
				"ss03", -- &: alternate ampersand
				"ss04", -- $: alternate dollar sign
				"ss05", -- @: alternate at symbol
				"ss07", -- =~ !~: tilde variations
				"ss09", -- >>= <<= ||= |= etc.
			},
		},

		-- Emoji font fallback (required for color emoji support)
		{ family = "Noto Color Emoji" },

		-- Last-resort fallback for box drawing / legacy glyphs
		-- Optional retro font for box drawing or legacy code pages
		-- { family = "LegacyComputing" },
		{
			family = "DejaVu Sans Mono",
		},
	})
end
