---@module 'config.fonts'
---@brief Font configuration for WezTerm using fallback and typographic ligatures

require("@types.types")

---@param Config WezTermConfig
---@return nil
return function(Config)
  --- Base font size in points
  Config.font_size = 12

  --- Font fallback list with typographic options
  Config.font = require('wezterm').font_with_fallback {
    -- Primary programming font
    {
      family = "JetBrainsMono Nerd Font",
      weight = "Regular",
      harfbuzz_features = {
        -- Character variants for better developer ergonomics:
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

    -- Optional retro font for box drawing or legacy code pages
    { family = "LegacyComputing" },
  }
end
