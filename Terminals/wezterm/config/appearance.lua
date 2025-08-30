---@module 'config.appearance'
---@brief UI appearance settings, tab bar, padding, opacity, and theming

---@param Config WezTermConfig
---@return nil
return function(Config)
  --- Set window background transparency
  Config.window_background_opacity = 0.5

  -- Add an explicit orange border around the window
  -- Width units can be 'px', 'pt' or cell-relative strings like '0.5cell'.
  Config.window_frame = {
    -- Titlebar background/underline (used with the fancy tab bar or CSD)
    --    active_titlebar_bg   = "#1e1e1e",
    --    inactive_titlebar_bg            = "#1e1e1e",
    --    active_titlebar_border_bottom   = "#ffa500",
    --    inactive_titlebar_border_bottom = "#ffa500",

    border_left_width    = "0.1cell",
    border_right_width   = "0.1cell",
    border_top_height    = "0.1cell",
    border_bottom_height = "0.1cell",
    border_left_color    = "#ffa500",
    border_right_color   = "#ffa500",
    border_top_color     = "#ffa500",
    border_bottom_color  = "#ffa500",
  }
end
