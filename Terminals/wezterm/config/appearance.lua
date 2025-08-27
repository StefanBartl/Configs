---@module 'config.appearance'
---@brief UI appearance settings, tab bar, padding, opacity, and theming

---@param Config WezTermConfig
---@return nil
return function(Config)
  --- Set window background transparency
  --Config.window_background_opacity = 0.75

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
  Config.use_fancy_tab_bar = true             -- Fancy appearance with icons, etc.
  Config.tab_bar_at_bottom = true
  Config.hide_tab_bar_if_only_one_tab = false -- Always show tab bar
  Config.show_new_tab_button_in_tab_bar = true
  Config.show_tab_index_in_tab_bar = false
  Config.show_tabs_in_tab_bar = true
  Config.switch_to_last_active_tab_when_closing_tab = false -- Do not jump to last
  Config.tab_and_split_indices_are_zero_based = false
  Config.tab_max_width = 25
end
