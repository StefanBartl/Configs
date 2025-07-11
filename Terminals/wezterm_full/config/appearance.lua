---@module 'config.appearance'
---@brief UI appearance settings, tab bar, padding, opacity, and theming
---@version 1.0

--@param Config WezTermConfig
--@return nil
return function(Config)
  --- Load a custom theme (Neapsix's Rose Pine via plugin)
  local theme = require('wezterm').plugin.require('https://github.com/neapsix/wezterm').main
  Config.colors = theme.colors()
  Config.window_frame = theme.window_frame() -- required for fancy tab bar look

  -- === Register custom color scheme ===

  ---@type HackTheBoxColorScheme
  local hackthebox_theme = require("color_schemes.hackthebox")

  -- Extract only the palette (excluding `.name`)
  local palette = {}
  for k, v in pairs(hackthebox_theme) do
    if k ~= "name" then
      palette[k] = v
    end
  end

  -- Register the palette
  Config.color_schemes = {
    [hackthebox_theme.name] = palette,
  }

  -- Activate it
  -- Config.color_scheme = hackthebox_theme.name

  --require("wezterm").on("set-color-hackthebox", function(window, pane)
  --  window:set_config_overrides({
  --    color_scheme = "Hack The Box",
  --  })
  --end)

  -- ======

  -- Alternative (if you want to fallback to built-in theme)
  -- Config.color_scheme = 'rose-pine'

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
  Config.enable_tab_bar = true                              -- Enable tab bar
  Config.use_fancy_tab_bar = true                           -- Fancy appearance with icons, etc.
  Config.tab_bar_at_bottom = true                           -- Show tabs at bottom
  Config.hide_tab_bar_if_only_one_tab = false               -- Always show tab bar
  Config.show_new_tab_button_in_tab_bar = true              -- Show [+] tab button
  Config.show_tab_index_in_tab_bar = false                  -- Hide tab index numbers
  Config.show_tabs_in_tab_bar = true                        -- Display tabs in UI
  Config.switch_to_last_active_tab_when_closing_tab = false -- Do not jump to last
  Config.tab_and_split_indices_are_zero_based = false       -- Tab 1 = index 1, not 0
  Config.tab_max_width = 25                                 -- Maximum width in cells
end
