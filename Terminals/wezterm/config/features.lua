---@module 'config.features'
---@brief features configuration for WezTerm
---@version 1.0

--@param Config WezTermConfig
--@return nil
return function(Config)
  Config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "NONE",
      action = require("wezterm").action { CopyTo = "ClipboardAndPrimarySelection" },
    },
  }
end

