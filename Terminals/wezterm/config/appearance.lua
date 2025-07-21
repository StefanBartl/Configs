---@module 'config.appearance'
---@brief UI appearance settings, tab bar, padding, opacity, and theming
---@version 1.1

--@param Config WezTermConfig
--@return nil
return function(Config)
  local wezterm = require("wezterm")

  --- Load a custom theme (Neapsix's Rose Pine via plugin)
 -- local theme = wezterm.plugin.require('https://github.com/neapsix/wezterm').main
  --Config.colors = theme.colors()
  --Config.window_frame = theme.window_frame() -- required for fancy tab bar look

  -- === Register custom color scheme ===

  --- Dynamisch geladen: plattformunabhängig
  --- Datei muss liegen unter: ~/.config/wezterm/color_schemes/hackthebox.lua (Linux)
  --- oder z.B.: E:/MyGithub/Configs/Terminals/wezterm/color_schemes/hackthebox.lua (Windows)
  --- ACHTUNG: Pfad trennt "/" auch unter Windows verwenden

  ---@type HackTheBoxColorScheme
  local hackthebox_theme = dofile("E:/MyGithub/Configs/Terminals/wezterm/color_schemes/hackthebox.lua")

  -- Extrahiere Palette (ohne .name)
  local palette = {}
  for k, v in pairs(hackthebox_theme) do
    if k ~= "name" then
      palette[k] = v
    end
  end

  --- Registriere Theme
  Config.color_schemes = {
    [hackthebox_theme.name] = palette,
  }

  --- Aktiviere Theme
  Config.color_scheme = hackthebox_theme.name

  --- Umschaltfunktion via WezTerm-Event (optional)
  wezterm.on("set-color-hackthebox", function(window, pane)
    window:set_config_overrides({
      color_scheme = hackthebox_theme.name,
    })
  end)

  -- Alternative (if you want to fallback to built-in theme)
  -- Config.color_scheme = 'rose-pine'


  -- ===  UI  ===

  --- Set window background transparency
  Config.window_background_opacity = 0.95

  --- Window padding (in pixels)
  Config.window_padding = {
    left = 2,
    right = 2,
    top = 2,
    bottom = 1,
  }

  --- Native titlebar button layout
  Config.integrated_title_button_alignment = "Right"
  Config.integrated_title_button_style = "Windows"
  Config.integrated_title_buttons = { "Hide", "Maximize", "Close" }

  --- Tab bar configuration
  Config.enable_tab_bar = true
  Config.use_fancy_tab_bar = true                           -- Fancy appearance with icons, etc.
  Config.tab_bar_at_bottom = true
  Config.hide_tab_bar_if_only_one_tab = false               -- Always show tab bar
  Config.show_new_tab_button_in_tab_bar = true
  Config.show_tab_index_in_tab_bar = false
  Config.show_tabs_in_tab_bar = true
  Config.switch_to_last_active_tab_when_closing_tab = false -- Do not jump to last
  Config.tab_and_split_indices_are_zero_based = false
  Config.tab_max_width = 25
end
