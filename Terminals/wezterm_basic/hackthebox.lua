-- ~/.config/wezterm/colors/hackthebox.lua

---@class WezTermColorScheme
return {
  name = 'Hack The Box',

  -- Standardfarben
  foreground = '#a4b1cd',
  background = '#1a2332',
  cursor_bg = '#a4b1cd',
  cursor_border = '#a4b1cd',
  cursor_fg = '#313f55',
  selection_bg = '#313f55',
  selection_fg = '#a4b1cd',

  -- ANSI-Farben (normal)
  ansi = {
    '#000000', -- black
    '#ff3e3e', -- red
    '#9fef00', -- green
    '#ffaf00', -- yellow
    '#004cff', -- blue
    '#9f00ff', -- magenta
    '#2ee7b6', -- cyan
    '#ffffff', -- white
  },

  -- ANSI-Farben (hell)
  brights = {
    '#666666', -- brightBlack
    '#ff8484', -- brightRed
    '#c5f467', -- brightGreen
    '#ffcc5c', -- brightYellow
    '#5cb2ff', -- brightBlue
    '#c16cfa', -- brightMagenta
    '#5cecc6', -- brightCyan
    '#ffffff', -- brightWhite
  },
}
